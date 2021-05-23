import 'package:archive/src/archive.dart';
import 'package:xml_test/epub/epub.dart';
import 'package:xml_test/xml/xnode.dart';
import 'package:xml_test/common.dart';

class BookDocument extends Epub
{
    /// Book docucument 
    var bookDocument = XNode.body();
    var textWriter = StringBuffer();
    var textClass = '';

    static final tagDef = 
    { 
        'div' : _TagDef('div',_TagDef.BLOCK_TAG),
        'p' :   _TagDef('p',_TagDef.BLOCK_TAG),
        'h1' :  _TagDef('h1',_TagDef.BLOCK_TAG),
        'h2' :  _TagDef('h2',_TagDef.BLOCK_TAG),
        'h3' :  _TagDef('h3',_TagDef.BLOCK_TAG),
        'h4' :  _TagDef('h4',_TagDef.BLOCK_TAG),
        'li':   _TagDef('li'),
    };

    BookDocument(Archive archive) : super(archive);

    void makeDocument()
    {
        bookDocument = XNode.body();
        textWriter.clear();
        textClass = '';

        for (var tag in bigDocument.children)
        {
            _makeTag(tag);
        }
    }

    void _makeTag(XNode node)
    {
        switch  (node.type)
        {
            case XNode.TEXT:
                if (textWriter.isEmpty || !isBlankOrNull(node.text))
                {
                    textWriter.write(node.text);
                }
                break;

            case XNode.ELEMENT:

                var  tag = tagDef[node.name];

                if (tag == null)
                {
                    for (var child in node.children)
                    {
                        _makeTag(child);
                    }

                }
                else
                {
                    _writeTag(tag.isBlockTag);

                    for (var child in node.children)
                    {
                        _makeTag(child);
                    }

                    _writeTag(tag.isBlockTag);


                }

        }
    }

    void _writeTag(bool block)
    {
        if (textWriter.isNotEmpty)
        {
            XNode para;
            if (block || bookDocument.children.isEmpty)
            {
                para = XNode(type:XNode.ELEMENT,name:'div');
                bookDocument.children.add(para);
            }
            else
            {
                para = bookDocument.children.last;
            }

            var span = XNode(type:XNode.ELEMENT,name:'span',
                            children: [XNode.text(textWriter.toString().trim())]);
            para.children.add(span);
            textWriter.clear();
        }

    }
}

class _TagDef
{
    static const INLINE_TAG   = 0;
    static const BLOCK_TAG    = 1;

    final String name;
    final int type;

    _TagDef(this.name,[this.type = INLINE_TAG]);

    XNode getXNode()
    {
        switch (type)
        {
            case BLOCK_TAG:
                return XNode(name: name, type: XNode.ELEMENT);

            default:
                return XNode(name: 'span', type: XNode.ELEMENT, attributes: { 'class' : name});
        }
    }

    bool get isBlockTag => type == BLOCK_TAG;
}

