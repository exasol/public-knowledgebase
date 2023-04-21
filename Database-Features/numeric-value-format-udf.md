# How to See All Currently Running Scripts

## Question
I have a Python UDF that will take a numeric value and apply an Excel like number format to produce a nicely formatted string value. This works really well, but performance is not optimal. Can anyone think of a more efficient way of doing this?  
```
CREATE OR REPLACE PYTHON SCALAR SCRIPT DASHBOARDS."UDF_FormatValue" ("Value" DECIMAL(32,6), "Format" VARCHAR(100) UTF8) RETURNS VARCHAR(255) UTF8 AS
#==============================================
#Description: This script formats a value based on a format pattern
#
#History:
#[03/27/2017] MJ Original Version
#[04/27/2017] MJ Fixed issue with function returning a decimal instead of a string
#[04/20/2018] MJ Added '#,##0' format
#[04/30/2018] MJ Expanded to accept conditonal formats and most Excel number formats
#[06/06/2018] MJ Added to code to evaluate the absolute value of a number for comparison to conditional formats
#==============================================
import re

def run(variables):
  def formatNumber(i,formatCode):
    units = {'k':1000, 'm':1000000,'b':1000000000} #specify unit divisors

    formats = formatCode.split(';') #split multiple conditions into a list
    for f in formats:
      numberformat = '{m}{{:{c}.{d}{p}}}{u}' #Python number format template
      comma = ''
      precision = 0
      percent = 'f'
      money = ''
      unit = ''
      divide = 1
      numberMatch = False

      condition = re.search(r'\[([><=]*)(\d*)\]',f) #check for conditional formatting
      if condition is not None:
        sign = condition.group(1)
        value = float(condition.group(2))
        #print(i, sign, value)
        iABS = abs(i)
        if sign == '>=':
          numberMatch = iABS >= value
        elif sign == '>':
          numberMatch = iABS > value
        elif sign == '<=':
          numberMatch = iABS <= value
        elif sign == '<':
          numberMatch = iABS < value
        elif sign == '=':
          numberMatch = iABS = value
      else: numberMatch = True

      if numberMatch:
        if f.find('$') > -1: money = '$'
        if f.find('%') > -1: percent = '%'
        if f.find(',') > -1: comma = ','
        if f.find('.') > -1: precision = f.count('0',f.find('.'))

        if f[-1:].lower() in (units):
          divide = units[f[-1:].lower()]
          unit = f[-1:]

        numberformat = numberformat.format(m=money,c=comma,d=precision,p=percent,u=unit) #constuct number format

        return numberformat.format(float(i)/divide)
  try:
    n = formatNumber(variables.Value,variables.Format)
    if n is None: #not a valid number format
      n = variables.Value
    return(str(n))
  except:
    return('')
/
```
## Answer
Solved this one myself with the suggestion to convert to a standard function in Exasol.  Solution below. This reduced compile time for some of my queries by 30 seconds! Apparently queries using Python UDFs have to spin up the language container.

```
CREATE OR REPLACE FUNCTION DASHBOARDS."FN_FormatValue" (val DECIMAL(18,8), form VARCHAR(100))
/*************************************************************
Description: This function formats a value based on a format pattern

History:
[04/27/2022] MJ Original Version (INFRA-6602)
************************************************************/
    RETURN VARCHAR(100)
    IS
        res VARCHAR(100);
        sign VARCHAR(1);
        scale DECIMAL;
        numberMatch BOOLEAN;
        cond BOOLEAN;
        formatCount DECIMAL;
        cForm VARCHAR(100);
        f DECIMAL;
        finalForm VARCHAR(100);
        divide DECIMAL;
        units VARCHAR(1);
        money VARCHAR(1);
        precision VARCHAR(10);
        percent DECIMAL;
        numbers VARCHAR(20);
        numberFormat VARCHAR(20);
    BEGIN
        formatCount := GREATEST(LENGTH(form)- LENGTH(REPLACE(form,';','')) +1 ,1);
        f := 0;
        numberMatch := FALSE;
        numbers := '9,999,999,999,990';
        WHILE f < formatCount AND numberMatch = FALSE DO --loop through multiple conditions
            f := f+1;
            sign := REGEXP_REPLACE(REGEXP_SUBSTR(form,'\[([><=]*)(\d*)\]([^;]*)',1,f),'\[([><=]*)(\d*)\]([^;]*)','\1');
            scale := CAST(REGEXP_REPLACE(REGEXP_SUBSTR(form,'\[([><=]*)(\d*)\]([^;]*)',1,f),'\[([><=]*)(\d*)\]([^;]*)','\2') AS DECIMAL(10));
            cForm := REGEXP_REPLACE(REGEXP_SUBSTR(form,'\[([><=]*)(\d*)\]([^;]*)',1,f),'\[([><=]*)(\d*)\]([^;]*)','\3');

            cond := sign IS NOT NULL;
            IF cond THEN
                IF sign = '>' THEN
                    numberMatch := val > scale;
                ELSEIF sign = '>=' THEN
                    numberMatch := val >= scale;
                ELSEIF sign = '<' THEN
                    numberMatch := val < scale;
                ELSEIF sign = '<=' THEN
                    numberMatch := val <= scale;
                END IF;
                IF numberMatch THEN
                    finalForm := cForm;
                END IF;
            ELSEIF cond = FALSE AND numberMatch = FALSE THEN
                finalForm := COALESCE(REGEXP_REPLACE(REGEXP_SUBSTR(form,'(?:.*;)(.*)',1),'(?:.*;)(.*)','\1'),form);
                numberMatch := TRUE;
            END IF;
        END WHILE;
        money := CASE WHEN INSTR(finalForm,'$')>0 THEN '$' ELSE '' END;
        percent := CASE WHEN INSTR(finalForm,'%')>0 THEN 100 ELSE 1 END;
        units := CASE WHEN INSTR(LOWER(finalForm),'k')>0 THEN 'k' WHEN INSTR(LOWER(finalForm),'m')>0 THEN 'm' WHEN INSTR(LOWER(finalForm),'b')>0 THEN 'b' ELSE '' END;
        precision := CASE WHEN INSTR(finalForm,'.')>0 THEN '.' || REPLACE(REPLACE(REGEXP_REPLACE(REGEXP_SUBSTR(finalForm,'\.([\d#]*)',1),'\.([\d#]*)','\1'),'0','9'),'#','0') ELSE '' END;
        numberFormat := CASE WHEN INSTR(finalForm,',')=0 THEN REPLACE(numbers,',','') ELSE numbers END || precision;
        divide := DECODE(units, 'k', 1000, 'm', 1000000, 'b',1000000000,1);
        res := money || TRIM(TO_CHAR((val*percent) / divide,numberFormat)) || units || CASE WHEN percent = 100 THEN '%' ELSE '' END;
        RETURN res ;
    END "FN_FormatValue";
/
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 