FROM apache/airflow
RUN pip install --no-cache-dir awscli hvac splunk-sdk
