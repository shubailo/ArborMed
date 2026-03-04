// Wait, is there a limit of 65535 parameters in node-postgres? Yes.
// Let's implement batching to be safe, e.g. chunks of 100 or 500 questions.
