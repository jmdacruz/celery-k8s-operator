import pytest
import requests
import time

def wait_for_workers(expected_workers=2, prefix="celery@add-operator-example-worker", limit=30, delay=1):
    iteration = 0 
    while iteration < limit:
        res = requests.get("http://localhost:8001/api/v1/namespaces/celery-example/services/add-operator-example-flower/proxy/api/workers?status=true")
        if res.status_code == 200:
            obj = None
            try:
                obj = res.json()
            except:
                pass
        if obj and len(obj) == 2 and all([key.startswith(prefix) for key in obj.keys()]):
            return
        time.sleep(delay)
        iteration += 1
    pytest.fail(f"A total of {expected_workers} worker(s) with prefix {prefix} was not available in under {delay*limit} seconds")


@pytest.mark.integration
def test_number_of_workers():
    wait_for_workers()

@pytest.mark.integration
def test_add_task():
    wait_for_workers()
    res = requests.post("http://localhost:8001/api/v1/namespaces/celery-example/services/add-operator-example-flower/proxy/api/task/apply/tasks.add", json={"args": [5, 6]})
    assert res.status_code == 200
    assert res.json()['result'] == 11
