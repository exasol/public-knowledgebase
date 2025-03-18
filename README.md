# Exasol Knowledge Base

## Welcome

Welcome to the Exasol Knowledge Base (KB)! This repository contains files and information needed to create a KB article.

Exasol KB articles must be created using Markdown (.md) format. If you are new to Markdown, see [Markdown Guide's Getting Started section](https://www.markdownguide.org/getting-started/). There are also many programs that will convert, say, Microsoft Word (.docx) files to Markdown files.

Your final article will be converted to HTML and rendered on the [Exasol Knowledge Base website](https://exasol.my.site.com). Please use only [basic Markdown syntax](https://www.markdownguide.org/basic-syntax/).

__Note__: Using other flavors of Markdown may not work as expected when rendered on Exasol's website. Even some basic syntax does not work as expected. For example, do not use [Blockquotes](https://www.markdownguide.org/basic-syntax/#blockquotes-1) ( `>` ).

## Templates

You can choose one of the following templates:

- [Question and Answer](Templates/QuestionAndAnswer.md): Pose a quick question with a specific answer.
- [Solution to a Problem](Templates/SolutionToAProblem.md): Provide workarounds for bugs or new shortcuts that you would like to share with others.
- [Tutorial](Templates/Tutorial.md): A quick tutorial for a specific task.

## Categories

The knowledge base provides five categories:

- Connect With Exasol
- Data Science
- Database Features
- Environment Management
- Support and Services

## Create a KB Article

1. Access the GitHub repository at [exasol\Public-Knowledgebase](https://github.com/exasol/Public-Knowledgebase).
1. In GitHub, click __Fork__ or create a new branch.
1. Select the appropriate template in the [Templates](/Templates) folder and copy the content.
1. Using your tool's commands, create a new file in the matching folder and copy the template's content into that file.  
1. Save the file in the appropriate category folder.
1. Write the article using styles listed in the Exasol Styles section of this readme and instructions in the template.
1. Each category folder contains a subfolder called __images__. If you have images, place them in your chosen category's __images__ folder. Make sure the size of each image does not exceed 1 MB.
1. We recommend you use a *Markdown linter* locally, to make sure required formatting rules are applied. The pull request you will create will be subject to a linter check online.
1. Once you are happy with the article, use your tool to commit and push the changes.
1. In GitHub, click __Pull request__, __New pull request__, and then click __Create pull request__.

## Limitations

Please keep in mind the following limitations when creating or modifying KB articles:

1. Images must not be larger than 1 MB.
1. Do not include the `<` or `>` symbols in your Markdown in plaintext parts of the article, they might get interpreted as HTML tags. If you need to use those symbols, use `&lt;` or `&gt;` instead to represent those characters.
1. Symbols `<` or `>` should, however, be used inside code blocks (triple ticks) and code inlines (single ticks).
1. Use `<br />` instead of `<br>`
1. Article should contain only one level 1 header (starting from a single hash sign #). Any content starting from the second single hash sign will not be rendered in Salesforce Knowledgebase.
1. Tables need to be separated from the surrounding text by at least one blank line from above and below.
1. As images should go to a special subfolder called "images", they should be further used via a path relative to a current folder, like (uppercase fragments are to be replaced accordingly)

```markdown
![SOME_CAPTION_THAT_SHOWS_UP_WHEN_YOU_HOVER_OVER_PIC](images/MYFILE.PNG)
```

## Exasol Styles

Exasol's official style guide is the [Google Style Guide](https://developers.google.com/style). Reference all questions there first. If the Google Style Guide does not answer your question, as the Google Style Guide recommends, go to the [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/welcome/).

Some Exasol styles do differ from Google and Microsoft, and Exasol is in the process of changing styles to more align with Google. Please scan the following style guide for information on Exasol specific styles.

### Links

- [Text formatting-summary](https://developers.google.com/style/text-formatting): Provides Google formatting notes for markdown documents.
- [Google Style Guide](https://developers.google.com/style)
- [Google Word List](https://developers.google.com/style/word-list)
- [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/welcome/): Use when the Google Style Guide doesn't answer your question.
- [Markdown Linter CLI 2]: An implementation of a Markdown syntax checker, which is also available as [plugin] for [Visual Studio Code]

<!-- link URL definitions used above -->
[Markdown Linter CLI 2]: https://github.com/DavidAnson/markdownlint-cli2
[plugin]: https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint
[Visual Studio Code]: https://code.visualstudio.com/
