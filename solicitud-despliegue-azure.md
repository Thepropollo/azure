# Solicitud de despliegue en Azure

Hola [Nombre],

Necesito publicar la aplicación del proyecto ULEAM en Azure, pero prefiero no solicitar permisos adicionales sobre la suscripción.

Datos de referencia:
- Usuario: e1316836327@live.uleam.edu.ec
- Suscripción: Azure for Students
- ID de suscripción: 6c6c1d17-320a-47e1-ab53-9912557c2cac

Si te parece bien, ¿puedes ejecutar el despliegue por mí usando el repositorio ubicado en:

`/home/thepropollo/Videos/azure`

El script preparado para el despliegue es:

`./azure-deploy.sh`

Ejemplo de ejecución:

```bash
cd /home/thepropollo/Videos/azure
chmod +x azure-deploy.sh
./azure-deploy.sh my-rg uleamacr uleam-webapp centralus
```

La aplicación ya está preparada para correr en contenedor Docker y se probó localmente con éxito.

Gracias.
