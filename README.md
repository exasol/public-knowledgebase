# Exasol Knowledge Base

## Welcome
Welcome to the Exasol Knowledge Base (KB)! This repository contains files and information needed to create a KB article.

Exasol KB articles must be created using Markdown (.md) format. If you are new to Markdown, see [Markdown Guide's Getting Started section](https://www.markdownguide.org/getting-started/). There are also many programs that will convert, say, Microsoft Word (.docx) files to Markdown files.

Your final article will be converted to HTML and rendered on the [Exasol Knowledge Base website](https://exasol.my.site.com). Please use only [basic Markdown syntax](https://www.markdownguide.org/basic-syntax/). 

__Note__: Using other flavors of Markdown may not work as expected when rendered on Exasol's website. Even some basic syntax does not work as expected. For example, do not use [Blockquotes](https://www.markdownguide.org/basic-syntax/#blockquotes-1) ( \> ).

## Templates
You can choose one of the following templates:
- [Question and Answer](Templates/QuestionAndAnswer.md): Pose a quick question with a specific answer.
- [Solution to a Problem](Templates/SolutionToAProblem.md): Provide workarounds for bugs or new shortcuts that you would like to share with others.
- [Tutorial](Templates/Tutorial.md): A quick tutorial for a specific task.
- [Explanation](Templates/Explanation.md): More information about a task or concept.

## Categories
The knowledge base provides five catagories:
- Connect With Exasol
- Data Science
- Database Features
- Environment Management
- Support and Services

## Create a KB Article
1. Access the GitHub repository at [exasol\Public-Knowledgebase](https://github.com/exasol/Public-Knowledgebase).
1. In GitHub, click __Fork__ and create a new branch.
1. Select the apporpriate template in the [Templates](/Templates) folder and copy the content.
1. Using your tool's commands, create a new file and copy the template's content into that file.  
1. Save the file in the appropirate category folder.
1. Write the article using styles listed in the Exasol Styles section of this readme and instructions in the template.
1. Each category folder contains a subfolder called __images__. If you have images, place them in your chosen category's __images__ folder. Make sure the size of each image does not exceed 1 MB.
1. Once you are happy with the article, use your tool to commit and push the changes.
1. In GitHub, click __Pull request__, __New pull request__, and then click __Create pull request__.

## Limitations
Please keep in mind the following limitations when creating or modifying KB articles:
1. Images must not be larger than 1 MB.
2. Do not include the < or > symbol in your Markdown. If you need to use the symbols, use "\&lt;" or "\%gt;" instead to represent those characters
3. Use \<br /> instead of \<br>
4. Article should contain only one level 1 header (starting from a single hash sign #). The content starting from the second hash sign will not be rendered in Salesforce Knowledgebase.

## Exasol Styles

Exasol's official style guide is the [Google Style Guide](https://developers.google.com/style). Reference all questions there first. If the Google Style Guide does not answer your question, as the Google Style Guide recommends, go to the [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/welcome/).

Some Exasol styles do differ from Google and Microsoft, and Exasol is in the process of changing styles to more align with Google. Please scan the following style guide for information on Exasol specific styles.

### Links
- [Text formatting-summary](https://developers.google.com/style/text-formatting): Provides Google formatting notes for markdown documents.

- [Google Style Guide](https://developers.google.com/style)
- [Google Word List](https://developers.google.com/style/word-list)
- [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/welcome/): Use when the Google Style Guide doesn't answer your question.
