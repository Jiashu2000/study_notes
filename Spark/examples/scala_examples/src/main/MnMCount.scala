// Counting and Aggregating M&Ms

import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

object MnMCount {

    def main(args: Array[String]): Unit = {
        val spark = SparkSession
        .builder
        .appName("MnMCount")
        .getOrCreate()

        if (args.length < 1) {
            print("Usage: MnMcount <MnM_file_dataset")
            sys.exit(1)
        }

    val mnmFile = args(0)

    val mnmDF = spark.read.format("csv")
        .option("header", "true")
        .option("inferSchema", "true")
        .load(mnmFile)

    val countMnMDF = mnmDF
        .select("State", "Color", "Count")
        .groupBy("State", "Color")
        .agg(count("Count").alias("Total"))
        .orderBy(desc("Total"))
    
    countMnMDF.show(60)
    println(s"Total Rows = ${countMnMDF.count()}")
    println()

    val caCountMnMDF = mnmDF
        .select("State", "Color", "Count")
        .where(col("State") === "CA")
        .groupBy("State", "Color")
        .agg(count("Count").alias("Total"))
        .orderBy(desc("Total"))
    
    caCountMnMDF.show(10)

    spark.stop()
    }
}