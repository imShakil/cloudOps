# Setup Prometheus

## Download and Install

- Get latest LTS version from [github release](https://github.com/prometheus/prometheus/releases)

Example:

- To install on Raspberry Pi:

```bash
wget https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-arm64.tar.gz
```

- To run

```bash
tar xvfz prometheus-*.tar.gz
cd prometheus-*
./prometheus --help
```

## Docker Compose Setup

- To install docker version with `docker copose`:

```bash
cd setup/prometheus
docker compose up -d
```



