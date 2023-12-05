# Axis and Dimmensions

## What is the Axis?

the Axis is something that represents the dimension of data

## Zero Dimensional data

A Scalar is zero-dimensional data. It has no dimensions or axis.

```python
4
```
## One Dimensional data
A Vector is one-dimensional data. Vector is a collection of Scalars. Vector has a shape (N,) , where N is the number of scalars in it.

```python
[1, 2, 3, 4]

np.sum([1, 2, 3, 4], axis = 0)
```

## Two Dimensional data
A Matrix is an example of two-dimensional data. Matrix is a collection of vectors and has a shape of (N,M) , where N is the number of vectors in it and M is the number of scalars in each vector.

The shape of the following example matrix would be(2,3).

[[1,2,3],
 [4,5,6]]

Matrix is a 2-dimensional data so it has 2 axes. Let’s see how to apply a Sum function along both axes.

```python
data = [[1,2,3],[4,5,6]]
np.sum(data, axis=0)
>> [5, 7, 9]

data = [[1,2,3],[4,5,6]]
np.sum(data, axis=1)
>> [6, 15]

data = [[1,2,3],[4,5,6]]
np.sum(data)
>> [21]
```

- Axis 0 will act on all the ROWS in each COLUMN
- Axis 1 will act on all the COLUMNS in each ROW