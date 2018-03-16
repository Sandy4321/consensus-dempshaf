module dempshaf.importidiom;

template from(string moduleName)
{
    mixin("import from = " ~ moduleName ~ ";");
}
