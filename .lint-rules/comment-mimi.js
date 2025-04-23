// Function to extract and process XML comments
function processXMLComments(token, errFunc) {
    const xmlCommentRegex = /<!--(.*?)-->/gs;
    const sqlCommentRegex = /(.*?)(--[^\n]*)/gs;

    if( token.type !== 'html_block' ) {
        // wrong token type
        return;
    }

    const match = xmlCommentRegex.exec(token.content);
    if ( match==null ) {
        // no XML comment
        return;
    }

    // check if the XML comment contains '--'
    let match2
    if ((match2 = sqlCommentRegex.exec(match[1])) !== null) {
        // and report it as an error if so
        const localLines = match2[1].split(/\n/).length - 1
        errFunc({
            "lineNumber": token.lineNumber + localLines,
            "detail": "forbidden '--' within XML comment",
            "context": match2[2]
        })
    }

    // console.log(token);
    return;
}

module.exports = {
    names: ["madcap-comment-mimi"],
    description: "Prevent -- within XML comments",
    // information: "This rule prevents later errors in the madCap conversion process",
    tags: [ "exasol", "madcap" ],
    // Define the actual function that checks the markdown
    "function": function rule(params, errFunc) {
        params.tokens.forEach(
            t => processXMLComments(t, errFunc)
        );
    }
};
