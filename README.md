# Laravel 11 con Docker

## 🛠️ Requisitos

- Docker 24.x o superior
- Docker Compose 2.x o superior
- Make

## 📦 Versiones de herramientas

| Herramienta | Versión |
|-------------|---------|
| PHP | 8.3.14 |
| Composer | 2.8.x |
| Node.js | 20.15.1 |
| NPM | 10.x |
| PostgreSQL | 16 Alpine |
| Redis | Alpine |
| Nginx | Alpine |

## 🚀 Instalación

### Primera vez (crear proyecto)
```bash
make init
```

### Otros desarrolladores (clonar proyecto)
```bash
git clone <repo>
cd project
make setup
make install-tools
```

## 🐘 PostgreSQL

### Comandos útiles

```bash
# Conectar a la base de datos
make db-shell

# Dentro de psql:
\l              # Listar bases de datos
\dt             # Listar tablas
\d users        # Describir tabla users
\q              # Salir

# Backup y restore
make db-backup
make db-restore file='backups/backup_20241019.sql'
```

## 🔍 Verificar versiones

```bash
make check-versions
```

## 🎨 Formateo de código

```bash
# Formatear todo el código
make format

# Verificar sin modificar
make format-check
```

## 📝 Commits

Este proyecto usa [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git commit -m "feat: nueva funcionalidad"
git commit -m "fix: corregir bug"
git commit -m "docs: actualizar README"
```

Tipos válidos: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`