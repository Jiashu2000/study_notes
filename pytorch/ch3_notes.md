# Chapter 3. Real-world data representation with tensors

- In fact, all operations within a neural network and during optimization are operations between tensors, and all parameters (such as weights and biases) in a neural network are tensors.

- Having a good sense of how to perform operations on tensors and index them effectively is central to using tools like PyTorch successfully.

- how do you take a piece of data, a video, or text, and represent it with a tensor, and do that in a way that are appropriate for training a deep learning model.

- We start with tabular data of data about wines, as you would find in a spreadsheet. Next, we move to ordered tabular data, with a time-series data set from a bike-sharing program. After that, we show you how to work with text data from Jane Austen. Text data retains the ordered aspect but introduces the problem of representing words as arrays of numbers. Because a picture is worth a thousand words, we demonstrate how to work with image data. Finally, we dip into medical data with a 3D array that represents a volume containing patient anatomy.

## Tabular data

- tabular data typically isn’t homogeneous; different columns don’t have the same type. PyTorch tensors, on the other hand, are homogeneous. Other data science packages, such as Pandas, have the concept of the data frame, an object representing a dataset with named, heterogenous columns. By contrast, information in PyTorch is encoded as a number, typically floating-point (though integer types are supported as well). Numeric encoding is deliberate, because neural networks are mathematical entities that take real numbers as inputs and produce real numbers as output through successive application of matrix multiplications and nonlinear functions.

- Your first job as a deep learning practitioner, therefore, is to encode heterogenous, real-world data in a tensor of floating-point numbers, ready for consumption by a neural network.

- <img src = "pics/ch3/wine.png" height = 250>

- wine quality example

- The two approaches have marked differences. Keeping wine-quality scores in an integer vector of scores induces an ordering of the scores, which may be appropriate in this case because a score of 1 is lower than a score of 4. It also induces some distance between scores. (The distance between 1 and 3 is the same as the distance between 2 and 4, for example.) If this holds for your quantity, great. If, on the other hand, scores are purely qualitative, such as color, one-hot encoding is a much better fit, as no implied ordering or distance is involved. One-hot encoding is appropriate for quantitative scores when fractional values between integer scores (such as 2.4) make no sense for the application (when score is either this or that).

- You can achieve one-hot encoding by using the scatter_ method. First, notice that its name ends with an underscore. This convention in PyTorch indicates that the method won’t return a new tensor but modify the tensor in place.

    ```python
    target_onehot = torch.zeros(target.shape[0], 10)
    target_onehot.scatter_(1, target.unsqueeze(1), 1.0)
    # Out[8]:
    tensor([[0., 0., ..., 0., 0.],
    [0., 0., ..., 0., 0.],
    ...,
    [0., 0., ..., 0., 0.],
    [0., 0., ..., 0., 0.]])
    ```

    - The dimension along which the following two arguments are specified
    - A column tensor indicating the indices of the elements to scatter
    - A tensor containing the elements to scatter or a single scalar to scatter (1, in this case)

- In other words, the preceding invocation reads this way: For each row, take the index of the target label (which coincides with the score in this case), and use it as the column index to set the value 1.0

- The second argument of scatter_, the index tensor, is required to have the same number of dimensions as the tensor you scatter into. Because target_onehot has two dimensions (4898x10), you need to add an extra dummy dimension to target by using unsqueeze:

```python
target_unsqueezed = target.unsqueeze(1)
target_unsqueezed

tensor([[6],
[6],
...,
[7],
[6]])
```

- The call to unsqueeze adds a singleton dimension, from a 1D tensor of 4898 elements to a 2D tensor of size (4898x1), without changing its contents. No elements were added; you decided to use an extra index to access the elements. That is, you accessed the first element of target as target[0] and the first element of its unsqueezed counterpart as target_unsqueezed[0,0]

- dim=0 indicates that the reduction is performed **_along dimension 0_**. At this point, you can normalize the data by subtracting the mean and dividing by the standard deviation, which helps with the learning process.

## Time Series

- data from a Washing ton, D.C., bike sharing system reporting the hourly count of rental bikes between 2011 and 2012 in the Capital bike-share system with the corresponding weather and seasonal information

- The goal is to take a flat 2D data set and transform it into a 3D one,

- <img src = "pics/ch3/weather.png" height = 300>

- We want to change the row-per hour organization so that you have one axis that increases at a rate of one day per index increment and another axis that represents hour of day (independent of the date). The third axis is different columns of data (weather, temperature, and so on).

- In a time-series data set such as this one, rows represent successive time points: a dimension along which they are ordered. This existence of an ordering, however, gives you the opportunity to exploit causal relationships across time. You can predict bike rides at one time based on the fact that it was raining at an earlier time

- This neural network model needs to see sequences of values for each quantity, such as ride count, time of day, temperature, and weather conditions. so N parallel sequences of size C. C stands for channel, in neural network parlance, and is the same as column for 1D data like you have here. The N dimension represents the time axis here, one entry per hour.

- You may want to break up the 2-year data set in wider observation periods, such as days. This way, you’ll have N (for number of samples) collections of C sequences of length L. In other words, your time-series data set is a tensor of dimension 3 and shape N x C x L. The C remains your 17 channels, and L would be 24, one per hour of the day.

- Now reshape the data to have three axes (day, hour, and then your 17 columns)

```python
# In[4]:
daily_bikes = bikes.view(-1, 24, bikes.shape[1])
daily_bikes.shape, daily_bikes.stride()
# Out[4]:
(torch.Size([730, 24, 17]), (408, 17, 1))
```

- First, the bikes.shape[1] is 17, which is the number of columns in the bikes tensor. But the real crux of the code is the call to view, which is important: it changes the way that the tensor looks at the same data as contained in storage.

- Calling view on a tensor returns a new tensor that changes the number of dimensions and the striding information without changing the storage.

- Use the -1 as a placeholder for however many indexes are left, given the other dimensions and the original number of elements.

- Remember that Storage is a contiguous, linear container for numbers—floating point, in this case. Your bikes tensor has rows stored one after the other in corresponding storage, as confirmed by the output from the call to bikes.stride() earlier.

- In other words, you now have N sequences of L hours in a day for C channels. To get to your desired NxCxL ordering, you need to transpose the tensor:

```python
daily_bikes = daily_bikes.transpose(1,2)
daily_bikes.shape, daily_bikes.stride()
# Out[5]:
(torch.Size([730, 17, 24]), (408, 1, 17))
```

## Text

- Networks operate on text at two levels: at character level, by processing one character at a time, and at word level, in which individual words are the finest-grained entities seen by the network.

- 