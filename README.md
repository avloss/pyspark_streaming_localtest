
# Testing PySpark Streaming Locally

PySpark Streaming has been around for a few years now. It's Spark's solution for processing data near-realtime. The
idea behind it, is to make Data Stream processing as easy as data processing. Though there are some commands specific to Spark Streaming. For instance **`updateStateByKey`**. So it can be non-straight forward to test it.

Let's start with a simple example and working towards testable PySpark Streaming code.

Let's create Spark Context first:


```python
from pyspark import SparkContext

sc = SparkContext("local[*]")
sc.setCheckpointDir("/tmp/spark_checkpoint")
```

Spark Streaming needs a checkpoint set to run some of it's operations, we are setting it here.

Let's make sure Spark Context works as expected


```python
sc.parallelize([1,2,3,4,5]).sum()
```




    15



---
This is easy to re-run and to test. Even quite complex transformations can be tested this way on a smaller sub-set of data


```python
(
    sc.parallelize("yes this will be another word count example unfortunately yes it will be just that".split())
    .map(lambda x: (x,1))
    .reduceByKey(lambda x,y: x+y)
    .collect()
)
```




    [('that', 1),
     ('this', 1),
     ('just', 1),
     ('unfortunately', 1),
     ('another', 1),
     ('will', 2),
     ('it', 1),
     ('yes', 2),
     ('be', 2),
     ('word', 1),
     ('count', 1),
     ('example', 1)]



---
Unfortunately when it comes to Spark Streaming it doesn't seem to be as easy to achieve the same result. If we start Spark Streaming Context we won't be able to add operations to it "as we go". The only way I found it possible to easily Spark Streaming was using following function.


```python
from pyspark.streaming import StreamingContext

BATCH_INTERVAL_SEC = 1
SCC_TIMEOUT = 2

def apply_with_spark_streaming(readings, transform):

    ssc = StreamingContext(sc, BATCH_INTERVAL_SEC)

    input_stream = ssc.queueStream(readings)

    transformed_readings=[]

    transformed_stream = transform(input_stream)

    transformed_stream.foreachRDD(lambda rdd: transformed_readings.append(rdd.collect()))

    ssc.start()

    ssc.awaitTerminationOrTimeout(SCC_TIMEOUT)

    stop_spark_context = False
    stop_gracefully = True
    ssc.stop(stop_spark_context, stop_gracefully)
    
    return transformed_readings
```


```python
batch1 = "yes this will be another word count example unfortunately yes it will be just that"
batch2 = "another batch from the example of word count"

def transform(dstream):
    return (dstream
           .map(lambda x: (x,1))
           .updateStateByKey(updateFunction)
           )

# taken from https://spark.apache.org/docs/latest/streaming-programming-guide.html#updatestatebykey-operation
def updateFunction(newValues, runningCount):
    if runningCount is None:
        runningCount = 0
    return sum(newValues, runningCount)

apply_with_spark_streaming([batch1.split(), batch2.split()], transform)
```




    [[('that', 1),
      ('this', 1),
      ('just', 1),
      ('unfortunately', 1),
      ('another', 1),
      ('will', 2),
      ('it', 1),
      ('yes', 2),
      ('be', 2),
      ('word', 1),
      ('count', 1),
      ('example', 1)],
     [('of', 1),
      ('that', 1),
      ('unfortunately', 1),
      ('just', 1),
      ('this', 1),
      ('another', 2),
      ('will', 2),
      ('it', 1),
      ('yes', 2),
      ('word', 2),
      ('be', 2),
      ('from', 1),
      ('batch', 1),
      ('the', 1),
      ('count', 2),
      ('example', 2)],
     [('of', 1),
      ('that', 1),
      ('unfortunately', 1),
      ('just', 1),
      ('this', 1),
      ('another', 2),
      ('will', 2),
      ('it', 1),
      ('yes', 2),
      ('word', 2),
      ('be', 2),
      ('from', 1),
      ('batch', 1),
      ('the', 1),
      ('count', 2),
      ('example', 2)],
     [('of', 1),
      ('that', 1),
      ('unfortunately', 1),
      ('just', 1),
      ('this', 1),
      ('another', 2),
      ('will', 2),
      ('it', 1),
      ('yes', 2),
      ('word', 2),
      ('be', 2),
      ('from', 1),
      ('batch', 1),
      ('the', 1),
      ('count', 2),
      ('example', 2)]]



---
So, what is happening here is that we define our `transform`, and then pass it along with a test dataset to `apply_with_spark_streaming`. Which starts Spark Streaming context and runs it for `SCC_TIMEOUT` seconds. after that we are shutting down Spart Streaming context, but not the Spark Context itself, this was we can re-run this function without restarting this notebook.
