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
SSH_KEY_PATH = os.environ.get("SSH_KEY_PATH", "/root/.ssh/id_rsa.pub")
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

def hunter_loop():
    state["status"] = "RUNNING"
    state["started_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    add_log("🚀 Iniciando cazador de instancias ARM en Oracle Cloud (2 OCPUs / 12 GB RAM)...")

    while state["status"] == "RUNNING":
        for ad in ADS:
            if state["status"] != "RUNNING":
                break
            
            state["attempts"] += 1
            state["current_ad"] = ad
            state["last_attempt_time"] = datetime.now().strftime("%H:%M:%S")
            
            add_log(f"Intentando en {ad} (Intento #{state['attempts']})...")

            cmd = [
                "oci", "compute", "instance", "launch",
                "--availability-domain", ad,
                "--compartment-id", COMPARTMENT_ID,
                "--shape", "VM.Standard.A1.Flex",
                "--shape-config", '{"ocpus": 2, "memoryInGBs": 12}',
                "--subnet-id", SUBNET_ID,
                "--image-id", IMAGE_ID,
                "--ssh-authorized-keys-file", SSH_KEY_PATH,
                "--display-name", "AlwaysFree-Ubuntu-ARM",
                "--assign-public-ip", "true"
            ]

            try:
                res = subprocess.run(cmd, capture_output=True, text=True, timeout=45)
                output = res.stdout + res.stderr

                if "lifecycle-state" in output:
                    state["status"] = "SUCCESS"
                    state["last_message"] = f"🎉 ¡ÉXITO! Instancia provista en {ad}."
                    state["provisioned_info"] = output
                    add_log(f"🎉 ¡ÉXITO TOTAL! Instancia provista en {ad}.")
                    add_log(output[:500])
                    return

                elif "OutOfCapacity" in output or "Out of host capacity" in output:
                    state["last_message"] = f"Sin capacidad en {ad}"
                    add_log(f" └─ Sin capacidad disponible en {ad}.")

                elif "LimitExceeded" in output:
                    state["status"] = "ERROR"
                    state["last_message"] = "Límite superado en el tenancy."
                    add_log(" └─ ERROR: Límite superado en OCI Tenancy.")
                    return

                else:
                    msg = "Respuesta de OCI recibida."
                    if "message" in output:
                        for line in output.splitlines():
                            if "message" in line.lower():
                                msg = line.strip()
                                break
                    state["last_message"] = msg
                    add_log(f" └─ {msg}")

            except subprocess.TimeoutExpired:
                state["last_message"] = "Timeout conectando a API OCI"
                add_log(f" └─ Timeout consultando API de OCI en {ad}.")
            except Exception as e:
                state["last_message"] = f"Error: {str(e)}"
                add_log(f" └─ Error de ejecución: {str(e)}")

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
