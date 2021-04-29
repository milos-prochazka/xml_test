
import 'package:xml/xml.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

class XNode
{
    static const TEXT_NAME = r'$TEXT$';
    static const COMMENT_NAME = r'$COMMENT$';
    static const DOCTYPE_NAME = r'$DOCTYPE$';
    static const DOCUMENT_NAME = r'$DOCUMENT$';
    static const DECLARATION_NAME = r'$XML$';
    static const CDATA_NAME = r'$CDATA$';

    static const UNKNOWN = 0;
    static const TEXT = 1;
    static const ELEMENT = 2;
    static const COMMENT = 3;
    static const DOCTYPE = 4;
    static const DOCUMENT = 5;
    static const DECLARATION = 6;
    static const CDATA = 7;

    var type       = UNKNOWN;
    var name       = '';
    var text       = '';
    var children   = <XNode>[];
    var attributes = <String,String>{};


    XNode.fromXmlNode(XmlNode node)
    {
        _fromXmlNode(node);
    }

    XNode.fromXmlDocument(XmlDocument document)
    {
        _fromXmlNode(document.root);
    }

    XNode.fromHtmlDocument(Document document)
    {
        _fromHtmlNode(document);
    }

    XNode.fromHtmlNode(Node node)
    {
        _fromHtmlNode(node);
    }

    XmlDocument toXmlDocument()
    {
        var builder = XmlBuilder();
        _buildXmlNode(builder);

        return builder.buildDocument();
    }

    Document toHtmlDocument()
    {
        var node = _buildHtmlNode();
        if (node is Document)
        {
            return node as Document;
        }
        else
        {
            var result = Document();
            if (node != null)
            {
                result.append(node);
            }
            return result;
        }
    }

    Node? _buildHtmlNode()
    {
        Node? node;

        switch(type)
        {
            case ELEMENT:
              node = Element.tag(name);
              break;

            case TEXT:
            case CDATA:
              node = Text(text);
              break;

            case COMMENT:
              node = Comment(text);
              break;

            case DOCUMENT:
              node = Document();
              break;

            case DOCTYPE:
              node = DocumentType(_emptyNull(text), _emptyNull(attributes['publicId']) , _emptyNull(attributes['systemId']));
              break;
        }

        if (node != null)
        {
            node.attributes.addAll(attributes);

            for(var child in children)
            {
                var childNode = child._buildHtmlNode();
                if (childNode != null)
                {
                    node.append(childNode);
                }
            }
        }

        return node;
    }

    void _buildXmlNode(XmlBuilder builder)
    {
        var buildChild= ()
        {
          for (var attribute in attributes.entries)
          {
              builder.attribute(attribute.key, attribute.value);
          }

          for(var childNode in children)
          {
              childNode._buildXmlNode(builder);
          }
        };

        switch (type)
        {
            case ELEMENT:
              builder.element(name,nest: buildChild);
              break;
            case TEXT:
              builder.text(text);
              break;
            case COMMENT:
              builder.comment(text);
              break;
            case DOCTYPE:
            case DECLARATION:
              builder.declaration(attributes: attributes);
              break;
            case CDATA:
              builder.cdata(text);
              break;
            case DOCUMENT:
              buildChild();
              break;
        }
    }

    void _fromHtmlNode(Node node)
    {
        switch (node.nodeType)
        {
            case Node.ELEMENT_NODE:
                type = ELEMENT;
                name = (node as Element).localName ?? 'div';
                break;

            case Node.TEXT_NODE:
                type = TEXT;
                name = TEXT_NAME;
                text = node.text ?? '';
                break;

            case Node.COMMENT_NODE:
                type = COMMENT;
                name = COMMENT_NAME;
                text = node.text ?? '';
                break;

            case Node.DOCUMENT_NODE:
                type = DOCUMENT;
                name = DOCUMENT_NAME;
                break;

            case Node.DOCUMENT_TYPE_NODE:
                var docType = node as DocumentType;
                type = DOCTYPE;
                name = DOCTYPE_NAME;
                text = docType.name?? '';
                attributes['publicId'] = docType.publicId ?? '';
                attributes['systemId'] = docType.systemId ?? '';
                break;

            default:
                type = UNKNOWN;
                break;
        }

        if (type != UNKNOWN)
        {
            for(var attribute in node.attributes.entries)
            {
                this.attributes[attribute.key.toString()] = attribute.value;
            }

            for(var childNode in node.nodes)
            {
                children.add ( XNode.fromHtmlNode( childNode));
            }
        }
    }

    void _fromXmlNode(XmlNode node)
    {
        if (node is XmlElement)
        {
            var element = node as XmlElement;
            name = element.name.local;
            type = ELEMENT;
        }
        else if (node is XmlText)
        {
            var txt = node as XmlText;
            name = TEXT_NAME;
            text = txt.text;
            type = TEXT;
        }
        else if (node is XmlComment)
        {
            var comment = node as XmlComment;
            name = COMMENT_NAME;
            text = comment.text;
            type = COMMENT;
        }
        else if (node is XmlDocument)
        {
            name = DOCUMENT_NAME;
            type = DOCUMENT;
        }
        else if (node is XmlDeclaration)
        {
            name = DECLARATION_NAME;
            type = DECLARATION;
        }
        else if (node is XmlCDATA)
        {
            var cdata = node as XmlCDATA;
            name = CDATA_NAME;
            text = cdata.text;
            type = CDATA;
        }
        else if (node is XmlDoctype)
        {
            var doctype = node as XmlDoctype;
            name = DOCTYPE_NAME;
            text = doctype.text;
            type = DOCTYPE;
        }
        else
        {
            type = UNKNOWN;
        }


        if (type != UNKNOWN)
        {
          for (var attribute in node.attributes)
          {
              attributes[attribute.name.local] = attribute.value;
          }

          for(var child in node.children)
          {
              var childNode = XNode.fromXmlNode(child);
              if (childNode.type != UNKNOWN)
              {
                  children.add(childNode);
              }
          }
        }

    }

    static String? _emptyNull(String? value)
    {
        if (value != null)
        {
            if (value.isEmpty)
            {
              value = null;
            }
        }

        return value;
    }


}