# ----------------------------------------------------
# --------	SQL Server 2017 Developer's Guide --------
# --------   Chapter 15 - Introducing Python  --------
# ----------------------------------------------------

# ----------------------------------------------------
# -- Section 1: Starting with Python
# ----------------------------------------------------

# A quick demo of Python capabilities
# Imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
# Reading a CSV file
TM = pd.read_csv("C:\SQL2017DevGuide\Chapter15_TM.csv")
# Pandas graphic
# Bar chart
obb = pd.crosstab(TM.NumberCarsOwned, TM.TotalChildren)
obb
obb.plot(kind = 'bar')
plt.show()
# Histogram and density plot
(TM['Age'] - 20).hist(bins = 25, normed = True, 
                      color = 'lightblue')
(TM['Age'] - 20).plot(kind='kde', style='r--', xlim = [0, 80])
plt.show()


# Introducting Python
# Hash starts a comment
print("Hello World!")
# Next command ignored
# print("Not executed")
print('Printing again.')
print('O"Hara')   # In-line comment
print("O'Hara")

# Mathematical and comparison operators
1 + 2
print("The result of 3 + 20 / 4 is:", 3 + 20 / 4)
10 * 2 - 7
10 % 4
print("Is 7 less or equal to 5?", 7 <= 5)
print("Is 7 greater than 5?", 7 > 5)
7 is 5
2 == 3
2 != 3
2 ** 3
2 / 3
2 // 3   # integer division
5 // 2

# Variables
# Integer
a = 2
b = 3
a ** b
# Case sensitivity
a + B
# NameError: name 'B' is not defined
# Float
c = 7.0
d = float(5)
print(c, d)

# Strings
e = "String 1"
f = "String 2"
print(e + ", " + f)
print("Let's concatenate %s and %s in a single string." % (e, f))
g = 10
print("Let's concatenate string %s and number %d." % (e, g))
# str.format()
four_cb = "String {} {} {} {}"
print(four_cb.format(1, 2, 3, 4))
print(four_cb.format("a", "b", "c", "d"))
# Multiple lines
print("""Note three double quotes.
Allow you to print multiple lines.
As many as you wish.""")
# Escaping characters
a = "I am 5'11\" tall"
b = 'I am 5\'11" tall'
print("\t" + a + "\n\t" + b)

# Importing a module - checking the version
import sys
help(sys)
sys.version

# Functions
def p_n():
    print("No args...")
def p_2(arg1, arg2):
    print("arg1: {}, arg2: {}".format(arg1, arg2))
def add(a, b):
    return a + b
# Usage
p_n()
p_2("a", "b")
# Call with variables and math
a = 10
b = 20
p_2(a / 5, b / 4)
add(10,20)

# if..elif..else
a = 10
b = 20
c = 30
if a > b:
    print("a > b")
elif a > c:
    print("a > c")
elif (b < c):
    print("b < c")
    if a < c:
        print("a < c")
    if b in range(10, 30):
        print("b is between a and c")
else:
    print("a is less than b and less than c")

# Lists and for loop
animals = ["cat", "dog", "pig"]
nums = []
for animal in animals:
    print("Animal: ", animal)
for i in range(2, 5):
    nums.append(i)
print(nums)

# While loop
s1 = "a b c d e f"
l1 = s1.split(' ')
l2 = ['g','h','i','j','k','l']
while len(l1) <= 10:
    x = l2.pop()
    l1.append(x)
    l1

# Dictionary
states = {
    "Oregon": "OR",
    "Florida": "FL",
    "Michigan": "MI"}
for state, abbrev in list(states.items()):
    print("{} is abbreviated {}.".format(state, abbrev))

# Classes and objects
class CityList(object):
    def __init__(self, cities):
        self.cities = cities
    def print_cities(self):
        for line in self.cities:
            print(line)
EU_Cities = CityList(["Berlin",
                      "Paris",
                      "Rome"])
US_Cities = CityList(["New York",
                      "Seattle",
                      "Chicago"])
EU_Cities.print_cities()
US_Cities.print_cities()


# ----------------------------------------------------
# -- Section 2: Working with Data
# ----------------------------------------------------

# numpy package
import numpy as np
np.__version__
# np arrays from lists
np.array([1, 2, 3, 4])
np.array([1, 2, 3, 4], dtype = "float32")
# Multidimensional arrays
np.zeros((3, 5), dtype = int)
np.ones((3, 5), dtype = int)
np.full((3, 5), 3.14)
# Range with steps
np.arange(0, 20, 2)
# Uniformly distributed numbers between 0 and 1
np.random.random((1, 10))
# Normally distributed numbers with mean 0 and stdev 1
np.random.normal(0, 1, (1, 10))
# Discrete uniform distribution of integers between 0 and 9
np.random.randint(0, 10, (3, 3))

# Attributes of an array
arr1 = np.random.randint(0, 12, size = (3, 4))
arr1.ndim
arr1.shape
# Accessing elements
arr1
arr1[1, 2]
arr1[0, -1]
# Slicing
arr1[1, :]
arr1[:, 1]

# Array concatenation
a1 = np.array([[1, 2, 3],
               [4, 5, 6]])
a2 = np.array([[7, 8, 9],
               [10, 11, 12]])
a3 = np.array([[10],
               [11]])
np.concatenate([a1, a2], axis = 0)
np.concatenate([a1, a3], axis = 1)
# Stacking
np.vstack([a1, a2])
np.hstack([a1, a3])
# Of course, next two lines produce errors
np.vstack([a1, a3])
np.hstack([a1, a2])

# numpy vectorized functions
x = np.arange(0, 9).reshape((3, 3))
x
np.sin(x)

# Aggregates
x = np.arange(1,6)
x
# Scalar aggregates
np.sum(x), np.prod(x)
np.min(x), np.max(x)
np.mean(x), np.std(x)
# Running sum of elements
np.add.accumulate(x)


# pandas package
import numpy as np
import pandas as pd
# Series
ser1 = pd.Series([1, 2, 3, 4])
ser1
ser1[1:3]
# Explicitly defined index
ser1 = pd.Series([1, 2, 3, 4],
                 index = ['a', 'b', 'c', 'd'])
ser1['b':'c']
# Creating series from a dictionary
dict1 = {'a': 1,
         'b': 2,
         'c': 3,
         'd': 4}
ser1 = pd.Series(dict1)
ser1

# DataFrame
age_dict = {'John': 35, 'Mick': 75, 'Diane': 42}
age = pd.Series(age_dict)
weight_dict = {'John': 88.3, 'Mick': 72.7, 'Diane': 57.1}
weight = pd.Series(weight_dict)
people = pd.DataFrame({'age': age, 'weight': weight})
people
# Metadata and projection
people.index
people.columns
people['age']

# Adding a column
people['WeightDivAge'] = people['weight'] / people['age']
people
# Transform rows to columns
people.T
# iloc, loc
people.iloc[0:2, 0:2]
people.loc['Diane':'John', 'age':'weight']
people.loc[people.age > 40, ['age', 'WeightDivAge']]

# Joining data frames
# Matching on the same key name - 1-1
df1 = pd.DataFrame({'Person': ['Mary', 'Dejan', 'William', 'Milos'],
                    'BirthYear': [1978, 1962, 1993, 1982]})
df2 = pd.DataFrame({'Person': ['Mary', 'Milos', 'Dejan', 'William'],
                    'Group': ['Accounting', 'Development', 'Training', 'Training']})
pd.merge(df1, df2)
# Explicit key name
pd.merge(df1, df2, on = 'Person')
# Matching on the same key name - 1-m
df3 = pd.DataFrame({'Group': ['Accounting', 'Development', 'Training'],
                    'Supervisor': ['Carol', 'Pepe', 'Shasta']})
pd.merge(df2, df3)
# Matching on the same key name - m-m
df4 = pd.DataFrame({'Group': ['Accounting', 'Accounting',
                              'Development', 'Development',
                              'Training'],
                    'Skills': ['math', 'spreadheets', 
                               'coding', 'architecture',
                               'presentation']})
pd.merge(df2, df4)


# ----------------------------------------------------
# -- Section 3: Data Science with Python
# ----------------------------------------------------

import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns

x = np.linspace(0.01, 10, 100)
y = np.sin(x)
z = np.log(x)

# Plot style
plt.style.use('classic')
# Simple graph
plt.plot(x, y)
plt.plot(x, z)
plt.show()

# Enhancing a graph and saving it to a file
f = plt.figure()
plt.plot(x, y, color = 'blue', linestyle = 'solid',
         linewidth = 4, label = 'sin')
plt.plot(x, z, color = 'red', linestyle = 'dashdot',
         linewidth = 4, label = 'log')
plt.axis([-1, 11, -2, 3.5])
plt.xlabel("X", fontsize = 16)
plt.ylabel("sin(x) & log(x)", fontsize = 16)
plt.title("Enhanced Line Plot", fontsize = 25)
plt.legend(fontsize = 16)
plt.show()
f.savefig('C:\\SQL2017DevGuide\\B08539_15_04.png')

# Supported formats
f.canvas.get_supported_filetypes()

# Reading a CSV file
TM = pd.read_csv("C:\SQL2017DevGuide\Chapter15_TM.csv")
# N of rows and cols
print (TM.shape)
# First 10 rows
print (TM.head(10))
# Some statistics
TM.mean()
TM.max()

# Scatterplot
TM1 = TM.head(100)
plt.scatter(TM1['Age'], TM1['YearlyIncome'])
plt.xlabel("Age", fontsize = 16)
plt.ylabel("YearlyIncome", fontsize = 16)
plt.title("YearlyIncome over Age", fontsize = 25)
plt.show()

# Seaborn plots

# Countplot
sns.countplot(x="Education", hue="BikeBuyer", data=TM);
plt.show()

# Education is categorical 
TM['Education'] = TM['Education'].astype('category')
TM['Education']
# Adding correct order
TM['Education'].cat.reorder_categories(
    ["Partial High School", 
     "High School","Partial College", 
     "Bachelors", "Graduate Degree"], inplace=True)
TM['Education']
# Repeat the countplot
f = plt.figure()
sns.countplot(x="Education", hue="BikeBuyer", data=TM);
plt.show()
f.savefig('C:\\SQL2017DevGuide\\B08539_15_05.png')

# Trellis charts
sns.set(font_scale = 3)
grid = sns.FacetGrid(TM, row = 'HouseOwnerFlag', col = 'BikeBuyer', 
                     margin_titles = True, size = 10)
grid.map(plt.hist, 'YearlyIncome', 
         bins = np.linspace(0, np.max(TM['YearlyIncome']), 7))
plt.show()

# Violin plot
sns.violinplot(x = 'Education', y = 'YearlyIncome',  
               data = TM, kind = 'box', size = 8)
plt.show()


# Machine learning

# Imports
import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from sklearn.naive_bayes import GaussianNB
from sklearn.mixture import GaussianMixture

# Reading a CSV file
TM = pd.read_csv("C:\SQL2017DevGuide\Chapter15_TM.csv")

# Naive Bayes
# Arrange the data - feature matrix and target vector
X = TM[['TotalChildren', 'NumberChildrenAtHome',
        'HouseOwnerFlag', 'NumberCarsOwned',
        'YearlyIncome', 'Age']]
X.shape
y = TM['BikeBuyer']
y.shape

# Split the data
Xtrain, Xtest, ytrain, ytest = train_test_split(
    X, y, random_state = 0, train_size = 0.7)

# Fit the model 
model = GaussianNB()
model.fit(Xtrain, ytrain)

# Make predictions and check the accuracy
ymodel = model.predict(Xtest)
accuracy_score(ytest, ymodel)


# Clustering
X = TM[['TotalChildren', 'NumberChildrenAtHome',
        'HouseOwnerFlag', 'NumberCarsOwned',
        'YearlyIncome', 'Age', 'BikeBuyer']]

# Fit the model
model = GaussianMixture(n_components = 2, covariance_type = 'full')
model.fit(X)

# Make predictions
ymodel = model.predict(X)
ymodel

# Add the cluster to the data
X['Cluster'] = ymodel
X.head()

# Plot the clusters
sns.set(font_scale = 3)
lm = sns.lmplot(x = 'YearlyIncome', y = 'Age', 
                hue = 'Cluster',  markers = ['o', 'x'],
                palette = ["orange", "blue"], scatter_kws={"s": 200},
                data = X, fit_reg = False,
                sharex = False, legend = True)
axes = lm.axes
axes[0,0].set_xlim(0, 190000)
plt.show(lm)


# SQL Server data
# Importing data from SQL Server using pyodbc
# Using the revoscalepy library
import numpy as np
import pandas as pd
import pyodbc;
from revoscalepy import rx_lin_mod, rx_predict, rx_summary

# Connecting and reading the data
con = pyodbc.connect('DSN=AWDW;UID=RUser;PWD=Pa$$w0rd')
query = """SELECT CustomerKey, Age,
             YearlyIncome, TotalChildren,
             NumberCarsOwned
           FROM dbo.vTargetMail;"""
TM = pd.read_sql(query, con)
TM.head(5)
TM.shape

# Check the summary of the NumberCarsOwned
summary = rx_summary("NumberCarsOwned", TM)
print(summary)

# Create a linear model
linmod = rx_lin_mod(
    "NumberCarsOwned ~ YearlyIncome + Age + TotalChildren", 
    data = TM)
predmod = rx_predict(linmod, data = TM, output_data = TM)
predmod.head(10)


# End of script