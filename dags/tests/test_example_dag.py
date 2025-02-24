from airflow.models import DagBag
import pytest

def test_dag_loaded(dagbag):
    dag = dagbag.get_dag(dag_id='example_dag')
    assert dagbag.import_errors == {}
    assert dag is not None
    assert len(dag.tasks) == 1

def test_dag_structure(dagbag):
    dag = dagbag.get_dag(dag_id='example_dag')
    task_ids = [task.task_id for task in dag.tasks]
    assert task_ids == ['print_hello']

def test_dag_defaults(dagbag):
    dag = dagbag.get_dag(dag_id='example_dag')
    assert dag.default_args['owner'] == 'airflow'
    assert dag.default_args['retries'] == 1

def test_dependencies(dagbag):
    dag = dagbag.get_dag(dag_id='example_dag')
    task = dag.get_task('print_hello')
    assert len(task.upstream_list) == 0
    assert len(task.downstream_list) == 0
