from airflow.models import DagBag
import pytest

def test_dag_loaded():
    """Test that the DAG file can be imported"""
    dagbag = DagBag(dag_folder='dags', include_examples=False)
    assert len(dagbag.import_errors) == 0, f"DAG import errors: {dagbag.import_errors}"
    assert 'example_dag' in dagbag.dags

def test_dag_structure():
    """Test the structure of the DAG"""
    dagbag = DagBag(dag_folder='dags', include_examples=False)
    dag = dagbag.dags['example_dag']
    assert dag is not None
    # Test tasks
    task_ids = [task.task_id for task in dag.tasks]
    assert 'print_hello' in task_ids

def test_dag_defaults():
    """Test the default arguments of the DAG"""
    dagbag = DagBag(dag_folder='dags', include_examples=False)
    dag = dagbag.dags['example_dag']
    assert dag.default_args['owner'] == 'airflow'
    assert dag.default_args['retries'] == 1

def test_dependencies():
    """Test task dependencies"""
    dagbag = DagBag(dag_folder='dags', include_examples=False)
    dag = dagbag.dags['example_dag']
    task = dag.get_task('print_hello')
    assert len(task.upstream_list) == 0  # No upstream tasks
    assert len(task.downstream_list) == 0  # No downstream tasks
