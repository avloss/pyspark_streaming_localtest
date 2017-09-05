#!/usr/bin/env bash

ipython nbconvert --to markdown Testin_PySpark_Streaming.ipynb
mv Testin_PySpark_Streaming.md README.md

docker build -t pyspark_streaming_localtest .

open http://0.0.0.0:8888/

docker run --rm -it -p 8888:8888  pyspark_streaming_localtest

