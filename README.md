# Repositorio de herramientas.

### replace-template.sh
* Clona un repositorio de Git.
* Siguiendo la siguiente estructura de directorios reemplaza los nombres de los archivos y directorios del backend para adecuarlos al nuevo proyecto
```
.
├── .devcontainer
│   ├── Dockerfile
│   └── devcontainer.json
├── server-config
│   └── docker-compose.yml
├── src
│   ├── backend
│   │   ├── Oct.MyProject
│   │   │   ├── Controllers
│   │   │   ├── Dockerfile
│   │   │   ├── Oct.MyProject.csproj
│   │   │   └── Program.cs
│   │   └── Oct.MyProject.sln
│   └── frontend
│       ├── docker
│       ├── e2e
│       └── src
├── tools
|   └── generate-version.sh
├── .gitlab-ci.yml
└── README.md
```
* Reemplaza todas las ocurrencias del nombre proyecto original
