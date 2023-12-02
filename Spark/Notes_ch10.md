# Chapter 10: Machine Learning with MLib

## Why Spark for Machine Learning?

- Spark has two machine learning packages: spark.mllib and spark.ml. spark.mllib is the original machine learning API, based on the RDD API (which has been in maintenance mode since Spark 2.0), while spark.ml is the newer API, based on DataFrames.

## MLlib terminology

- Transformer: 

    Accepts a DataFrame as input, and returns a new DataFrame with one or more columns appended to it. Transformers do not learn any parameters from your data and simply apply rule-based transformations to either prepare data for model training or generate predictions using a trained MLlib model.

- Estimator
    
    Learns (or “fits”) parameters from your DataFrame via a .fit() method and returns a Model, which is a transformer.

- Pipeline

    Organizes a series of transformers and estimators into a single model. While pipelines themselves are estimators, the output of pipeline.fit() returns a Pipe lineModel, a transformer.

## Designing Machine Learning Pipelines

#### Data Ingestion and Exploration

```SCALA
val file_path = "./data/sf-airbnb/sf-airbnb-clean.parquet/"
val airbnbDF = spark.read.parquet(file_path)

airbnbDF.select("neighbourhood_cleansed", "room_type","bedrooms", "bathrooms", "number_of_reviews", "price").show(5)
```

#### Creating Training and Test Data Sets

#### Preparing Features with Transformers

- Transformers in Spark accept a DataFrame as input and return a new DataFrame with one or more columns appended to it. They do not learn from your data, but apply rule-based transformations using the transform() method. 

- We will use the VectorAstransformer transformer. VectorAssembler takes a list of input columns and creates a new DataFrame with an additional column, which we will call features.

```scala
import org.apache.spark.ml.feature.VectorAssembler

val vecAssembler = new VectorAssembler()
    .setInputCols(Array("bedrooms"))
    .setOutputCol("features")

val vecTrainDF = vecAssembler.transform(trainDF)
vecTrainDF.select("bedrooms", "features", "price").show(10)

```

#### Using Estimators to Build Models

-  lr.fit() returns a LinearRegressionModel (lrModel), which is a transformer. Once the estimator has learned the parameters, the transformer can apply these parameters to new data points to generate predictions

```scala
import org.apache.spark.ml.regression.LinearRegression

val lr = new LinearRegression()
    .setFeaturesCol("features")
    .setLabelCol("price")

val lr_model = lr.fit(vecTrainDF)
```

#### Creating a Pipeline

```scala
import org.apache.spark.ml.Pipeline

val pipeline = new Pipeline().setStages(Array(vecAssembler, lr))
val pipeline_model = pipeline.fit(trainDF)
```

- Since pipelineModel is a transformer, it is straightforward to apply it to our test dataset too:

```scala
val pred_df = pipeline_model.transform(testDF)
pref_df.select("bedrooms", "features", "price", "prediction").show(10)
```

- **_One-hot encoding_**

- Most machine learning models in MLlib expect numerical values as input, represented as vectors. To convert categorical values into numeric values, we can use a technique called one-hot encoding (OHE).

- If we had a zoo of 300 animals, would OHE massively increase consumption of memory/compute resources? Not with Spark! Spark internally uses a SparseVector when the majority of the entries are 0, as is often the case after OHE, so it does not waste space storing 0 values

    - DenseVector(0, 0, 0, 7, 0, 2, 0, 0, 0, 0)
    - SparseVector(10, [3, 5], [7, 2])

- There are a few ways to one-hot encode your data with Spark. A common approach is to use the StringIndexer and OneHotEncoder. With this approach, the first step is to apply the StringIndexer estimator to convert categorical values into category indices. These category indices are ordered by label frequencies, so the most frequent label gets index 0, which provides us with reproducible results across various runs of the same data. 

- Once you have created your category indices, you can pass those as input to the OneHotEncoder. The OneHotEncoder maps a column of category indices to a column of binary vectors. 

```python
# In Python
from pyspark.ml.feature import OneHotEncoder, StringIndexer

categoricalCols = [field for (field, dataType) in trainDF.dtypes if dataType == "string"] 
indexOutputCols = [x + "Index" for x in categoricalCols]
oheOutputCols = [x + "OHE" for x in categoricalCols]

stringIndexer = StringIndexer(inputCols=categoricalCols, outputCols=indexOutputCols, handleInvalid="skip")

oheEncoder = OneHotEncoder(inputCols=indexOutputCols, outputCols=oheOutputCols)

numericCols = [field for (field, dataType) in trainDF.dtypes if ((dataType == "double") & (field != "price"))]

assemblerInputs = oheOutputCols + numericCols

vecAssembler = VectorAssembler(inputCols=assemblerInputs, outputCol="features")
```

- “How does the StringIndexer handle new categories that appear in the test data set, but not in the training data set?” There is a handleInvalid parameter that specifies how you want to handle them. The options are skip (filter out rows with invalid data), error (throw an error), or keep (put invalid data in a special additional bucket, at index numLabels).

- Another approach is to use RFormula.

    RFormula will automatically StringIndex and OHE all of your string columns, convert your numeric columns to double type, and combine all of these into a single vector using VectorAssembler under the hood

```scala
import org.apache.spark.ml.feature.RFormula

val rFormula = new RFormula()
    .setFormula("price ~ .")
    .setFeaturesCol("features")
    .setLabelCol("price")
    .setHandleInvalid("skip")
```

- The downside of RFormula automatically combining the StringIndexer and OneHotEncoder is that one-hot encoding is not required or recommended for all algorithms. For example, tree-based algorithms can handle categorical variables directly if you just use the StringIndexer for the categorical features. You do not need to onehot encode categorical features for tree-based methods, and it will often make your tree-based models worse.

```scala

val lr = new LinearRegression()
    .setLabelCol("price")
    .setFeaturesCol("fetures")

val pipelin = new Pipeline()
    .setStages(Array(stringIndexer, oheEncoder, vecAssembler, lr))

val pipelineModel = pipeline.fit(trainDF)
val predDF = pipelineModel.transform(testDF)

predDF.select("features", "price", "prediction").show()

```

## Evaluating Models

```scala
import org.apache.spark.ml.evaluation.RegressionEvaluator

val regressionEvaluator = new RegressionEvaluator()
    .setPredictionCol("prediction")
    .setLabelCol("price")
    .setMetricName("rmse")

val rmse = regressionEvaluator.evaluate(predDF)
println(f"RMSE is $rmse%.1f")
```

## Saving and Loading Models

- Now that we have built and evaluated a model, let’s save it to persistent storage for reuse later (or in the event that our cluster goes down, we don’t have to recompute the model). Saving models is very similar to writing DataFrames—the API is model.write().save(path). You can optionally provide the overwrite() command to overwrite any data contained in that path:

```scala
val pipeline_path = "lr_model_path"
pipeline_model.write.overwrite().save(pipeline_path)

import org.apache.spark.ml.PipelineModel
val savedPipelineModel = PipelineModel.load(pipeline_path)
```

## Hyperparameter Tuning

- A hyperparameter is an attribute that you define about the model prior to training, and it is not learned during the training process (not to be confused with parameters, which are learned in the training process).

```python
from pyspark.ml.regression import DecisionTreeRegressor

dt = DecisionTreeRegressor(labelCol = "price")

numericCols = [field for (field, dataType) in trainDF.dtypes
                if ((dtypes == "double") & (field != "price"))]

assemblerInputs = indexOutputCols + numericCols
vecAssembler = VectorAssembler(inputCols = assemblerInputs, outputCol = "features")

stages = [stringIndexer, vecAssembler, dt]
pipeline = Pipeline(stages = stages)

pipeline_model = pipeline.fit(trainDF)
```

- maxBins determines the number of bins into which your continuous features are discretized, or split.

- This discretization step is crucial for performing distributed training. There is no maxBins parameter in scikit-learn because all of the data and the model reside on a single machine. In Spark, however, workers have all the columns of the data, but only a subset of the rows. Thus, when communicating about which features and values to split on, we need to be sure they’re all talking about the same split values.

- Every worker has to compute summary statistics for every feature and every possible split point, and those statistics will be aggregated across the workers

- MLlib requires maxBins to be large enough to handle the discretization of the categorical columns. The default value for maxBins is 32, and we had a categorical column with 36 distinct values, which is why we got the error earlier.

```python
dt.setMaxbins(40)
pipelineModel = pipeline.fit(trainDF)
```

- Now that we have successfully built our model, we can extract the if-then-else rules learned by the decision tree:

```python
dt_model = pipelineModel.stages[-1]
print(dt_model.toDebugString)
```

- We can also extract the feature importance scores from our model to see the most important features:

```python
import pandas as pd
featureImp = pd.DataFrame(
    list(zip(vecAssembler.getInputCols(), dtModel.featureImportances)),
    columns = ["feature", "importance"]
)

featureImp.sort_values(by = "importance", ascending = False)
```

- Random forests

    - Ensembles work by taking a democratic approach

    - Random forests are an ensemble of decision trees with two key tweaks

        1. Bootstrapping samples by rows

            Bootstrapping is a technique for simulating new data by sampling with replacement from your original data. Each decision tree is trained on a different bootstrap sample of your data set, which produces slightly different decision trees, and then you aggregate their prediction.

            This technique is known as bootstrap aggregating, or bagging. In a typical random forest implementation, each tree samples the same number of data points with replacement from the original data set, and that number can be controlled through the subsamplingRate parameter.

        2. Random feature selection by columns

            The main drawback with bagging is that the trees are all highly correlated, and thus learn similar patterns in your data

            To mitigate this problem, each time you want to make a split you only consider a random subset of the columns (1/3 of the features for RandomForestRegressor and #features for RandomForestClassifier). Due to this randomness you introduce, you typically want each tree to be quite shallow.
    
    ```python
    from pyspark.ml.regression import RandomForestRegressor
    rf = RandomForestRegressor(labelCol = "price", maxBins = 40, seed = 42)
    ```

    - Random forests truly demonstrate the power of distributed machine learning with Spark, as each tree can be built independently of the other trees (e.g., you do not need to build tree 3 before you build tree 10). Furthermore, within each level of the tree, you can parallelize the work to find the optimal splits

- k-Fold Cross-Validation

    1. Define the estimator you want to evaluate.

    2. Specify which hyperparameters you want to vary, as well as their respective values, using the ParamGridBuilder.

    3. Define an evaluator to specify which metric to use to compare the various models.
    
    4. Use the CrossValidator to perform cross-validation, evaluating each of the various models.

    ```python
    pipeline = Pipeline(stages = [stringIndexer, vecAssembler, rf])

    from pyspark.ml.tuning import ParamGridBuilder

    paramGrid = (ParamGridBuilder()
                .addGrid(rf.maxDepth, [2, 4, 6])
                .addGrid(rf.numTrees, [10, 100]
                .build()))
    
    evaluator = RegressionEvaluator(labelCol = "price",
                    predictionCol = "prediction",
                    metricName = "rmse"
                )
    
    from pyspark.ml.tuning import CrossValidator

    cv = CrossValidator(estimator = pipeline,
                    evaluator = evaluator,
                    estimatorParamMaps = paramGrid,
                    numFolds = 3,
                    seed = 42)
    cvModel = cv.fit(trainDF)

    list(zip(cvModel,getEstimatorParamMaps(), cvModel.avgMetrics))
    ```

#### Optimizing Pipelines

```python
cvModel = cv.setParallelism(4).fit(trainDF)
```