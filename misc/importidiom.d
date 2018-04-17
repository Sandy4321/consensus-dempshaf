module dempshaf.misc.importidiom;

template from(string moduleName)
{
    mixin("import from = " ~ moduleName ~ ";");
}
