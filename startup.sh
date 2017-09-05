#!/usr/bin/env bash

export PYTHONPATH=/spark/python/lib/py4j-0.10.4-src.zip:/spark/python/lib/pyspark.zip
export SPARK_HOME=/spark
/miniconda3/bin/jupyter notebook \
                                --port=8888 \
                                --no-browser \
                                --ip=0.0.0.0 \
                                --notebook-dir=/notebook \
                                --NotebookApp.token='' \
                                --allow-root