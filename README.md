# php-phalcon-base

Imagem base usada por **php-api**, **timeline** e **reports-php**:
PHP 8.4 FPM (Debian bookworm) + Phalcon 5.23 + extensões `opcache pdo_mysql zip gd exif` +
nginx + supervisord + locales `pt_BR/es_ES/en_US` + composer.

Compilar o Phalcon é a parte lenta do build. Com esta imagem pronta no Docker Hub, os projetos
só baixam a base e seguem direto para `composer install` e cópia do código.

Imagem: `SEU_USUARIO/php-phalcon` — tags `8.4-5.23.0`, `8.4-5.23` e `latest`
(multi-arch: `linux/amd64` para CI/EC2 e `linux/arm64` para Mac Apple Silicon).

## Configuração (uma vez)

1. No Docker Hub, crie o repositório `php-phalcon` (pode ser **público**: não há código nem segredo na imagem).
2. Em *Account settings → Personal access tokens*, gere um token **Read & Write**.
3. Crie este repo no GitHub (`jesselopespereira/php-phalcon-base`) e, em
   *Settings → Secrets and variables → Actions*, adicione:
   - Variable `DOCKERHUB_USERNAME` = seu usuário/organização do Docker Hub
   - Secret `DOCKERHUB_TOKEN` = o token do passo 2
4. Faça push na `main` (ou rode o workflow manualmente em *Actions → Build & Push base image*).
   O primeiro build demora (o arm64 roda via QEMU), mas só acontece aqui.

O workflow roda de novo quando o `Dockerfile` muda e uma vez por mês (patches de segurança na mesma tag).

## Build manual (alternativa, do Mac)

```bash
docker login
docker buildx create --use --name multi 2>/dev/null || docker buildx use multi
docker buildx build --platform linux/amd64,linux/arm64 \
  -t SEU_USUARIO/php-phalcon:8.4-5.23.0 \
  -t SEU_USUARIO/php-phalcon:8.4-5.23 \
  -t SEU_USUARIO/php-phalcon:latest \
  --push .
```

## Atualizar versão do PHP ou Phalcon

1. Mude `PHP_VERSION` / `PHALCON_VERSION` no workflow (e os defaults no `Dockerfile`).
2. Push → nova tag é publicada (ex.: `8.4-5.24.0`).
3. Nos projetos, troque o `ARG BASE_IMAGE=...` do topo dos Dockerfiles para a nova tag.

## O que fica na base x nos projetos

| Base (este repo) | Cada projeto |
|---|---|
| PHP, Phalcon, extensões, nginx, supervisord, locales, composer | `php.ini`, `app.ini`, pool do FPM, sites do nginx, `supervisord.conf` |
| | `composer install`, código, models, build do frontend (Node) |
| | Dev: `git`, `curl`, `xz-utils` e Node (10 no timeline, 14 no reports-php) |

Para testar outra base sem editar o Dockerfile: `docker build --build-arg BASE_IMAGE=usuario/imagem:tag ...`
