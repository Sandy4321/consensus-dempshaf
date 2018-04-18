module dempshaf.misc.importidiom;

/**
 * From is an import idiom that allows you to specify a symbol's
 * module in the arguments list without having to import the symbol
 * in the current module's scope.
 */
template from(string moduleName)
{
    mixin("import from = " ~ moduleName ~ ";");
}
