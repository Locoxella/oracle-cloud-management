# 🕹️ Guía Rápida para Humanos: Acceso a VMs

Esta es la guía simplificada para acceder a tus nodos en Oracle Cloud sin complicaciones técnicas innecesarias.

## 🚀 Método Recomendado: Un Solo Comando (Automatizado)

El repositorio incluye un script que crea la sesión en OCI Bastion, gestiona los puertos aleatorios, abre el túnel y limpia todo automáticamente al salir:

### Conectar a Atlas-Node-01 (AMD):
```bash
./connect_vm.sh
# o explícitamente:
./connect_vm.sh amd
```

### Conectar a AlwaysFree-Ubuntu-ARM (ARM):
```bash
./connect_vm.sh arm
```

### Ejecutar un comando remoto directo sin abrir sesión interactiva:
```bash
./connect_vm.sh "docker ps"
./connect_vm.sh arm "uptime"
```

---

## 🛠️ Método Manual (Paso a Paso con OCI CLI)

Si por alguna razón necesitas gestionar la sesión manualmente:

### Paso 1: Crear la Sesión (Solo una vez cada 3 horas)

Copia y pega este comando en tu terminal local:

```bash
oci bastion session create-port-forwarding \
    --bastion-id "ocid1.bastion.oc1.iad.amaaaaaainltkcaaor463mvd7hxxcyqxpsmnhn3ptr5rdh7h5pvqesqekyma" \
    --display-name "Human-Access" \
    --ssh-public-key-file "~/.ssh/id_rsa.pub" \
    --target-resource-id "ocid1.instance.oc1.iad.anuwcljtinltkcac5f3wz76gl4vpx7g6mp3lf2ofwjsjcbuoxqz4vine2wlq" \
    --target-port 22 \
    --session-ttl 10800
```

*Guarda el ID de sesión que te devuelva el comando.*

### Paso 2: Obtener el comando de conexión

Reemplaza `<SESSION_ID>` con el ID del paso anterior:

```bash
oci bastion session get --session-id <SESSION_ID>
```

Busca en el resultado la línea que empieza con `ssh -i ...` dentro del campo `ssh-metadata`.

### Paso 3: Abrir el Túnel

Pega ese comando largo en una terminal y déjalo abierto. Se verá algo así:
`ssh -i <llave> -N -L 2222:10.0.0.160:22 ...`

### Paso 4: Entrar a la VM

En **otra terminal**, escribe esto para finalmente entrar:

```bash
ssh -i ~/.ssh/id_rsa -p 2222 ubuntu@localhost
```

---

## 🔍 Comandos de Emergencia

### ¿Mis "Hunters" (scripts de caza) siguen vivos?

```bash
ps aux | grep _hunter.sh
```

### ¿Qué están cazando ahora mismo?

```bash
tail -f ~/repos/oracle-cloud-management/memory/scripts/arm_hunter.log
# o
tail -f ~/repos/oracle-cloud-management/memory/scripts/amd_2_hunter.log
```

### Detener todos los Hunters

```bash
pkill -f _hunter.sh
```
