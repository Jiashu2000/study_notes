# Chapter 5: Stateful Computation

#### Stateful & Stateless

- a stateless program looks at each individual event and creates some output based on the last event. for example, a streaming program might receive temperature readings from a sensor and raise an alert if the temperature goes beyond 90 degrees. 

- a stateful program maintains state that is updated based on every input and produces output based on the last input and the current value of the state.

- <img src = "pics/stateless_stateful.png"/>

## Notion of Consistency

- consistency is a different word for **_"level of correctness"_**. how correct are my results after a failure and a successful recovery compared to what I would have gotten without any failure.

    1. **_at most once_**: no correctness guarantees. the count may be lost after a failure.
    2. **_at least once_**: the count value may be bigger than but never smaller than the correct ouput.
    3. **_exactly once_**: exactly once means that the system guarantees that the count will be exactly the same as it would be in the failure-free scenario.

- the first solutions that provided exactly once came at a substantial cost in terms of performance and expresiveness. in order to guarantee exactly once beahvaior, these systems do not apply the application logic to each record separately, but instead process several (a batch of) records at a time, guaranteeing that either the processing of each batch will succeed as a whole or not at all. For this reason, users were often left having to use two stream processing frameworks together (one for exactly once and one for per-element, low-latency processing), resulting in even more complexity in the infrastructure.

- one significant value that flink has brought to the industry is that it is able to provide exactly once guarantees, low-latency processing, and high throughput all at once.

## Flink Checkpoints: Guaranteeing Exactly Once

- flink makes use of a feature known as "checkpoint". the role of flink checkpoints is to guarantee correct state, even after a program interruption.

```scala
val stream: DataStream[(String, Int)] = ...
val count: DataStream[(String, Int)] = stream
    .keyBy(record => record._1)
    .mapWithState((in: (String, Int), count: Option[Int])=>
    count match {
        case Some(c) => ((in._1, c + in._2), some(c + in._2))
        case None => ((in._1, in._2, some(in._2)))
    })
```

- there are two operations in the program: the **_keyBy_** operator groups the incoming records by the first element (a string), repartitions the data based on that key, and forwards the records to the next operator: the **_stateful map_** operator. The map operator receives each element, advances the count by adding up the second field of the input record to the current count.

- <img src = 'pics/start_condition.png' width = 450/>

- starting condition for the program. Note that initial state for record groups a, b, and c is zero in each case, shown as values on the three cylinders. Checkpoint barriers are shown as black 'ckpt' records. each record is strictly before or after a checkpoint in sequence of processsing.

- <img src = "pics/checkpoint_barrier.png" width = 450/>

- when a flink data source encounters a checkpoint barrier, it records the position of the barrier in the input stream to stable storage. This will allow flink to later restart the input from that position.

- <img src = "pics/checkpoint_ans.png" width = 450/>

- at this point, the positions of the checkpoint barriers in the input stream have already been backed up in stable storage. the map operators are now processing the checkpoint barriers, triggering an asynchronous backup of their state in stable storage.

- <img src = "pics/checkpoint_success.png" width = 450/>

- consider the situation, with the checkpoint having successfully completed and a failure occurring right after the checkpoint.

- <img src = "pics/checkpoint_fail.png" width = 450/>

- flink will restart the topology (possibly acquiring new execution resources), rewind the input stream to the positions registered in the last checkpoint, and restore the state values and continue execution from there. in the example, it means that records ("a", 2), ("a", 2), ("c", 2) will be replayed.

- <img src = "pics/checkpoint_restore.png" width = 450/>

- the algorithm used for checkpointing in flink is formally called **_Asynchronous Barrier Snapshotting_**.

## Savepoints: Versioning State

- flink users also have a way to consciously manage versions of state through a feature called **_savepoints_**.

- a savepoint is taken in exactly the same way as a checkpoint but is triggered manually by the user. you can think of savepoints as snapshots of a job at a certain time.

- another way to think about savepoints is saving versions of the application state at well-defined times.

- <img src = "pics/savepoints.png" width = 450/>
- here we have a running version of an application (version 0) and took a savepoint of our application at time t1 and a savepoint at t2.

- we are able to start a modified version of a program from a savepoint.

- <img src = 'pics/savepoint_newversion.png' width = 450/>

- we have both version 0 and version 0.1 of the programs running at the same time while taking subsequent savepoints to both versions at later times.

- savepoints used to solve a variety of production issues

    1. application code upgrades
    2. flink version upgrades
    3. maintenance and migration
    4. what-if simulations
    5. a/b testing

## End-to-End Consistency and the Stream Processor as a Database
 

- <img src = 'pics/application_architecture.png' width = 450/>

- application architecture consisting of a stateful flink application consuming data from a message queue and writing data to an output system used for querying. the callout shows what goes on inside the flink application.

- a partitioned storage system (eg. a message queue such Kafka or MapR streams) serves as the data input. the flink topology consists of three operators: the data source reads data from the input, partitions it by key, and routes records to instances of the stateful operations, which can be a mapWithState as we saw in the previous section, a window aggregation. This operator writes the contents of the state or some derivative results to a sink, which transfers these to a partitioned storage system that serves as output storage. a query service then allows users to query the state.

 - how can we transfer the contents of the state to the output with exactly once guarantee? (end-to-end exactly once)

    1. the first way is to buffer all output at the sink and commit this atomically
