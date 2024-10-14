import pytest

def test_passwd_file(host):
    passwd = host.file("/etc/passwd")
    assert passwd.contains("root")
    assert passwd.user == "root"
    assert passwd.group == "root"
    assert passwd.mode == 0o644


def test_docker_running_and_enabled(host):
    docker = host.service("docker")
    assert docker.is_running
    assert docker.is_enabled

def test_traefik_running_and_enabled(host):
    traefik = host.docker("traefik")
    assert traefik.is_running


@pytest.mark.parametrize("service_name", [
    "promtail",
    "sshwifty",
    "loki",
    "traefik-forward-auth",
    "traefik",
    "mafl",
    "casdoor",
    "prometheus",
    "grafana",
    "node-exporter",
    "watchtower",
    "portainer",
    "mafl-service-discovery",
    "dockge",
    "dozzle",
    "cadvisor",
])
def test_core_docker_running_and_enabled(host, service_name):
    service = host.docker(service_name)
    assert service.is_running

@pytest.fixture(scope="module")
def ip_address(host):
    return host.run("curl -4 https://ifconfig.me").stdout.strip()

def test_auth_url_loads(host, ip_address):
    url = f"https://auth.{ip_address}.traefik.me"
    print(f"Testing URL: {url}")
    response = host.run(f"curl -k -s -o /dev/null -w '%{{http_code}}' {url}")
    assert response.stdout == "200"

def test_www_url_loads(host, ip_address):
    url = f"https://www.{ip_address}.traefik.me"
    print(f"Testing URL: {url}")
    response = host.run(f"curl -k -s -o /dev/null -w '%{{http_code}}' {url}")
    assert response.stdout == "307" # Redirects to auth

def check_root_free_space(host):
    root_partition = host.run("df / --output=avail -B1 | tail -n1").stdout.strip()
    assert int(root_partition) > 2000000000 # 2GB
