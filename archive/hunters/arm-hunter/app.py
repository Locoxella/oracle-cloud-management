import os
import time
import subprocess
import threading
from datetime import datetime
from flask import Flask, render_template, jsonify

app = Flask(__name__)

# OCI Configuration
COMPARTMENT_ID = "ocid1.tenancy.oc1..aaaaaaaacdo7v2uzdflqej637btfq53aeztwpnk3epxz64e7int3pcy5dxwa"
SUBNET_ID = "ocid1.subnet.oc1.iad.aaaaaaaauuz6jqxlsduhikx37zo33zm5thxybhb2ppx7ltvulhfhq6ralzoa"
IMAGE_ID = "ocid1.image.oc1.iad.aaaaaaaaawgpyvs3zh7tu5343gpj45yqcj6hosrmrgvo5xovc7dvjwgi4vaq"
def get_default_ssh_key():
    for key_name in ["id_ed25519.pub", "id_rsa.pub"]:
        path = os.path.expanduser(f"~/.ssh/{key_name}")
        if os.path.exists(path):
            return path
    return os.path.expanduser("~/.ssh/id_rsa.pub")

SSH_KEY_PATH = os.environ.get("SSH_KEY_PATH", get_default_ssh_key())
ADS = ["nHMH:US-ASHBURN-AD-1", "nHMH:US-ASHBURN-AD-2", "nHMH:US-ASHBURN-AD-3"]

# Global State
state = {
    "status": "STOPPED", # STOPPED, RUNNING, SUCCESS, ERROR
    "attempts": 0,
    "last_attempt_time": None,
    "current_ad": None,
    "last_message": "Inicializando...",
    "logs": [],
    "started_at": None,
    "provisioned_info": None
}

MAX_LOGS = 100

def add_log(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {msg}"
    state["logs"].append(entry)
    if len(state["logs"]) > MAX_LOGS:
        state["logs"].pop(0)
    print(entry, flush=True)

import sys
import oci

def get_compute_client():
    config = oci.config.from_file()
    return oci.core.ComputeClient(config)

def hunter_loop():
    state["status"] = "RUNNING"
    state["started_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    add_log("🚀 Iniciando cazador de instancias ARM en Oracle Cloud (2 OCPUs / 12 GB RAM)...")
    
    if not os.path.exists(SSH_KEY_PATH):
        state["status"] = "ERROR"
        err = f"No se encontró la clave pública SSH en: {SSH_KEY_PATH}"
        state["last_message"] = err
        add_log(f"❌ ERROR CRÍTICO: {err}")
        return

    with open(SSH_KEY_PATH, "r") as f:
        ssh_authorized_key = f.read().strip()

    add_log(f"🔑 Clave SSH cargada correctamente ({SSH_KEY_PATH})")

    try:
        compute_client = get_compute_client()
        add_log("📡 Cliente OCI SDK inicializado correctamente.")
    except Exception as e:
        state["status"] = "ERROR"
        err = f"Error cargando credenciales OCI: {str(e)}"
        state["last_message"] = err
        add_log(f"❌ ERROR CRÍTICO: {err}")
        return

    while state["status"] == "RUNNING":
        for ad in ADS:
            if state["status"] != "RUNNING":
                break
            
            state["attempts"] += 1
            state["current_ad"] = ad
            state["last_attempt_time"] = datetime.now().strftime("%H:%M:%S")
            
            add_log(f"Intentando en {ad} (Intento #{state['attempts']})...")

            launch_details = oci.core.models.LaunchInstanceDetails(
                availability_domain=ad,
                compartment_id=COMPARTMENT_ID,
                display_name="AlwaysFree-Ubuntu-ARM",
                shape="VM.Standard.A1.Flex",
                shape_config=oci.core.models.LaunchInstanceShapeConfigDetails(
                    ocpus=2,
                    memory_in_gbs=12
                ),
                source_details=oci.core.models.InstanceSourceViaImageDetails(
                    image_id=IMAGE_ID
                ),
                create_vnic_details=oci.core.models.CreateVnicDetails(
                    subnet_id=SUBNET_ID,
                    assign_public_ip=True
                ),
                metadata={
                    "ssh_authorized_keys": ssh_authorized_key
                }
            )

            try:
                response = compute_client.launch_instance(launch_details)
                instance = response.data
                
                state["status"] = "SUCCESS"
                state["last_message"] = f"🎉 ¡ÉXITO! Instancia provista en {ad} (OCID: {instance.id})."
                state["provisioned_info"] = str(instance)
                add_log(f"🎉 ¡ÉXITO TOTAL! Instancia provista en {ad}.")
                add_log(f"ID: {instance.id} | Estado: {instance.lifecycle_state}")
                return

            except oci.exceptions.ServiceError as se:
                if se.status == 500 or "out of host capacity" in se.message.lower() or se.code == "OutOfCapacity":
                    state["last_message"] = f"Sin capacidad en {ad}"
                    add_log(f" └─ Sin capacidad disponible en {ad} (OutOfCapacity - 500).")
                elif se.code == "LimitExceeded":
                    state["status"] = "ERROR"
                    state["last_message"] = f"Límite superado: {se.message}"
                    add_log(f" └─ ❌ ERROR de Límites OCI: {se.message}")
                    return
                else:
                    state["last_message"] = f"Error OCI ({se.code}): {se.message}"
                    add_log(f" └─ ⚠️ Error OCI [{se.status} {se.code}]: {se.message}")

            except oci.exceptions.RequestException as re:
                state["last_message"] = f"Error de red/timeout: {str(re)}"
                add_log(f" └─ ⚠️ Timeout de red consultando OCI: {str(re)}")

            except Exception as e:
                state["last_message"] = f"Error inesperado: {str(e)}"
                add_log(f" └─ ❌ Error inesperado: {type(e).__name__} - {str(e)}")

        if state["status"] == "RUNNING":
            add_log("⏳ Ciclo completado. Esperando 60 segundos antes del siguiente intento...")
            time.sleep(60)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/status")
def get_status():
    return jsonify(state)

@app.route("/api/control/<action>", methods=["POST"])
def control(action):
    if action == "start" and state["status"] in ["STOPPED", "ERROR"]:
        thread = threading.Thread(target=hunter_loop, daemon=True)
        thread.start()
        return jsonify({"status": "ok", "message": "Cazador iniciado"})
    elif action == "stop":
        state["status"] = "STOPPED"
        state["last_message"] = "Detenido por el usuario."
        add_log("🛑 Cazador detenido por el usuario.")
        return jsonify({"status": "ok", "message": "Cazador detenido"})
    return jsonify({"status": "error", "message": "Acción no válida"}), 400

if __name__ == "__main__":
    thread = threading.Thread(target=hunter_loop, daemon=True)
    thread.start()
    app.run(host="0.0.0.0", port=5000)
