# How does Exasol determine the data type of a multiplication 
## Question

How does Exasol determine the data type of a multiplication of different dataypes?

Example: what data type is the result when you multiply database columns number (18,3) by number (18,9)?

Can numeric overflows occur?

## Answer

In operations with multiple operands (e.g. the operators +,-,/,*) the operands are implicitly converted to the biggest occurring data type (e.g. DOUBLE is bigger than DECIMAL) before executing the operation. This rule is also called numeric precedence.

Numeric overflow can occur and result in a data exception - numeric value out of range.

The result for this specific calculation would be decimal (36,12).  
Regularly the precision and scale were added.  
Examples:

```
(12,0) * (15,3) = (27,3)
(12,0) * (15,9) = (27,9)
(18,3) * (18,9) = (36,12)
```

For sums the scale is taken from the factor with the highest precision.

```
(12,0) + (15,9) = (22,9)
(15,3) + (15,9) = (22,9)
```
