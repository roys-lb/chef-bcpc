import pytest

@pytest.mark.parametrize("name", [
    pytest.param("nova-api", marks=pytest.mark.headnodes),
    pytest.param("nova-scheduler", marks=pytest.mark.headnodes),
    pytest.param("nova-consoleauth", marks=pytest.mark.headnodes),
    pytest.param("nova-conductor", marks=pytest.mark.headnodes),
    pytest.param("nova-novncproxy", marks=pytest.mark.headnodes),
    pytest.param("nova-scheduler", marks=pytest.mark.headnodes),
    pytest.param("nova-compute", marks=pytest.mark.worknodes),
    pytest.param("nova-api-metadata", marks=pytest.mark.worknodes),
])
def test_services_head(host, name):
    s = host.service(name)
    assert s.is_running
    assert s.is_enabled

@pytest.mark.headnodes
@pytest.mark.worknodes
@pytest.mark.production
def test_memcache_config(host):
    nova_conf = host.file("/etc/nova/nova.conf")
    assert nova_conf.contains("backend = oslo_cache.memcache_pool")
    assert nova_conf.user == "root"
    assert nova_conf.group == "nova"
    assert nova_conf.mode == 0o640

@pytest.mark.headnodes
@pytest.mark.production
def test_nova_version(host):
    nova_pkg = host.package("nova-api")
    assert nova_pkg.is_installed
    assert nova_pkg.version == "2:18.0.3-0ubuntu2~cloud0"
