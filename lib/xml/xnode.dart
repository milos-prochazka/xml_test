import 'package:xml/xml.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'package:xml_test/common.dart';

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_this

class XNode implements InterfaceToDynamic, ICloneable<XNode> 
{
    static const TEXT_NAME = r'$TEXT$';
    static const COMMENT_NAME = r'$COMMENT$';
    static const DOCTYPE_NAME = r'$DOCTYPE$';
    static const DOCUMENT_NAME = r'$DOCUMENT$';
    static const DECLARATION_NAME = r'$XML$';
    static const CDATA_NAME = r'$CDATA$';

    /// Unknown node type
    static const UNKNOWN = 0;

    /// Text node type
    static const TEXT = 1;

    /// Element node type <div>
    static const ELEMENT = 2;

    /// Comment node type <!-- -->
    static const COMMENT = 3;

    /// Doctype node type <!DOCTYPE>
    static const DOCTYPE = 4;

    /// Document node type
    static const DOCUMENT = 5;

    /// document declaration node type
    static const DECLARATION = 6;

    /// CDATA node type
    static const CDATA = 7;

    var type = UNKNOWN;
    var name = '';
    var text = '';
    var children = <XNode>[];
    var attributes = <String, String>{};
    var linkedData = <String, dynamic>{};

    /// Map to convert blank html characters to spaces
    /// - Converts blank characters to a space (0x20) or null (0x0) to remove characters
    static final htmlSpacesConversionMap = <int, int>{0x9: 0x20, 0xa: 0x00, 0xb: 0x00, 0xc: 0x00, 0xd: 0x00};

    /// Constructor
    /// [type] - Node type eg. TEXT, ELEMENT
    /// [name] - Node name eg. div
    /// [text] - Node text
    /// [attributes] - Map of attributes <element attr1='val1'  attr2='val2' ... >
    /// [children] - List of child nodes
    XNode({int? type, String? name, String? text, Map<String, String>? attributes, List<XNode>? children}) 
    {
        if (type != null) 
        {
            this.type = type;
        }
        if (name != null) 
        {
            this.name = name;
        }
        if (text != null) 
        {
            this.text = text;
        }

        if (attributes != null) 
        {
            for (var attr in attributes.entries) 
            {
                this.attributes[attr.key] = attr.value;
            }
        }

        if (children != null) 
        {
            for (var child in children) 
            {
                this.children.add(child);
            }
        }
    }

    /// Constructor [DOCUMENT]
    XNode.document() 
    {
        type = DOCUMENT;
        name = DOCTYPE_NAME;
    }

    /// Constructor <body> element
    XNode.body() 
    {
        type = ELEMENT;
        name = 'body';
    }

    /// Constructor [COMMENT] element
    XNode.comment(this.text) 
    {
        type = COMMENT;
        name = COMMENT_NAME;
    }

    XNode.text(this.text) 
    {
        type = TEXT;
        name = TEXT_NAME;
    }

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

    /// Constructor - deep copy from another XNode object
    factory XNode.fromXNode(XNode node) 
    {
        XNode result = XNode(name: node.name, text: node.text, type: node.type, attributes: node.attributes);

        result.addChildrenFrom(node);
        result.addLinkedDataFrom(node);

        return result;
    }

    void addLinkedDataFrom(XNode node) 
    {
        for (final data in node.linkedData.entries) 
        {
            final value = data.value;
            linkedData[data.key] = value is ICloneable ? (value as ICloneable).clone() : value;
        }
    }

    void addChildrenFrom(XNode node) 
    {
        for (final child in node.children) 
        {
            children.add(child.clone());
        }
    }

    XmlDocument toXmlDocument() 
    {
        var builder = XmlBuilder();
        _buildXmlNode(builder);

        return builder.buildDocument();
    }

    @override
    XNode clone() 
    {
        return XNode.fromXNode(this);
    }

    Document toHtmlDocument() 
    {
        XNode node = this;

        switch (node.type) 
        {
            case DOCUMENT:
            case DOCTYPE:
                // TODO: Proverit doctype
                break;

            case UNKNOWN:
                node = XNode.document();
                break;

            default:
                // TODO: Dodelat pro jine nez body
                var document = XNode(type: DOCUMENT, name: DOCTYPE_NAME, children: 
                [
                    XNode(type: ELEMENT, name: 'html', children: [node]),
                ]);
                node = document;
                break;
        }

        return node._buildHtmlNode() as Document;
    }

    List<XNode> getChildren(List<String> childPath, {Set<String>? childNames}) 
    {
        var result = <XNode>[];
        var parentNode = _findNode(childPath);

        if (parentNode != null) 
        {
            for (var child in parentNode.children) 
            {
                if (childNames == null || childNames.contains(child.name)) 
                {
                    result.add(child);
                }
            }
        }

        return result;
    }

    bool attributeContains(String name, String pattern, [bool caseSensitive = false]) 
    {
        final attrText = attributes[name];

        return (attrText == null)
                ? false
                : caseSensitive
                        ? attrText.contains(pattern)
                        : attrText.toLowerCase().contains(pattern.toLowerCase());
    }

    @override
    dynamic toDynamic(bool embeded) 
    {
        var attr = <String, String>{};

        for (var item in attributes.entries) 
        {
            attr[item.key] = item.value;
        }

        var chlist = <dynamic>[];
        for (var item in children) 
        {
            chlist.add(item.toDynamic(embeded));
        }

        var result = <String, dynamic>{'type': type, 'name': name, 'text': text, 'attributes': attr, 'children': chlist};

        if (embeded) 
        {
            var linkedMap = <String, dynamic>{};
            for (var item in linkedData.entries) 
            {
                if (item.value is InterfaceToDynamic) 
                {
                    linkedMap[item.key] = (item.value as InterfaceToDynamic).toDynamic(embeded);
                }
            }

            result['linkedData'] = linkedMap;
        }

        return result;
    }

    void comressHtmlText({bool nested = false, bool truncate = false, bool removeBlankText = false}) 
    {
        if (type == TEXT && text != '') 
        {
            var codeUnits = text.codeUnits;
            var chars = <int>[];

            for (var ch in codeUnits) 
            {
                var conv = htmlSpacesConversionMap[ch] ?? -1;
                switch (conv) 
                {
                    case -1:
                        chars.add(ch);
                        break;
                    case 0:
                        break;
                    default:
                        chars.add(conv);
                        break;
                }
            }

            int start = 0;
            int end = chars.length;

            if (truncate) 
            {
                while (start < end && chars[start] == 0x20) start++;
                while (end > start && chars[end - 1] == 0x20) end--;
            }

            text = (end > start) ? String.fromCharCodes(chars, start, end) : '';
        }

        if (nested) 
        {
            for (int i = 0; i < children.length;) 
            {
                var child = children[i];
                child.comressHtmlText(nested: nested, truncate: truncate, removeBlankText: removeBlankText);
                if (removeBlankText && child.type == TEXT && child.text == '') 
                {
                    children.removeAt(i);
                } 
                else 
                {
                    i++;
                }
            }
        }
    }

    XNode? _findNode(List<String> childPath) 
    {
        XNode node = this;

        for (int i = 0; i < childPath.length; i++) 
        {
            var name = childPath[i];

            node = node.children.firstWhere((element) => element.name == name, orElse: () => _nullNode);

            if (node == _nullNode) 
            {
                return null;
            }
        }

        return node;
    }

    Node? _buildHtmlNode() 
    {
        Node? node;

        switch (type) 
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
                node = DocumentType(_emptyNull(text), _emptyNull(attributes['publicId']), _emptyNull(attributes['systemId']));
                break;
        }

        if (node != null) 
        {
            node.attributes.addAll(attributes);

            for (var child in children) 
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
        var buildChild = () 
        {
            for (var attribute in attributes.entries) 
            {
                builder.attribute(attribute.key, attribute.value);
            }

            for (var childNode in children) 
            {
                childNode._buildXmlNode(builder);
            }
        };

        switch (type) 
        {
            case ELEMENT:
                builder.element(name, nest: buildChild);
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
                text = docType.name ?? '';
                attributes['publicId'] = docType.publicId ?? '';
                attributes['systemId'] = docType.systemId ?? '';
                break;

            default:
                type = UNKNOWN;
                break;
        }

        if (type != UNKNOWN) 
        {
            for (var attribute in node.attributes.entries) 
            {
                this.attributes[attribute.key.toString()] = attribute.value;
            }

            for (var childNode in node.nodes) 
            {
                children.add(XNode.fromHtmlNode(childNode));
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

            for (var child in node.children) 
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

    static final _nullNode = XNode();
}

/// The XNode tree representation.
class TreeNode 
{
    TreeNode? parent;
    TreeNode? firstChild;
    TreeNode? lastChild;
    TreeNode? prev;
    TreeNode? next;

    // List of classes (<element class="class1 class2">)
    var classes = <String>[];

    // Element id
    var id = '';

    /// Embedded XNode element
    late XNode xnode;

    /// Construcor - empty object
    TreeNode() 
    {
        xnode = XNode();
    }

    /// Contructor - form XNode
    /// - Clone of an XNode object without children
    TreeNode.fromXNode(XNode srcNode) 
    {
        TreeNode? _prevChild;

        // Clone of an srcNode (withoud childred)
        final node = XNode(type: srcNode.type, text: srcNode.text, name: srcNode.name, attributes: srcNode.attributes);
        node.addLinkedDataFrom(srcNode);

        this.xnode = node;

        final clsAttr = node.attributes['class'];
        if (clsAttr != null) 
        {
            this.classes = clsAttr.splitEx([' ', '\t']);
        }

        this.id = node.attributes['id'] ?? '';

        for (var child in srcNode.children) 
        {
            final _treeChild = TreeNode.fromXNode(child);
            _treeChild.parent = this;

            if (_prevChild == null) 
            {
                firstChild = _treeChild;
            } 
            else 
            {
                _prevChild.next = _treeChild;
                _treeChild.prev = _prevChild;
            }

            lastChild = _treeChild;
            _prevChild = _treeChild;
        }
    }

    /// Adds a child TreeNode
    void addChild(TreeNode treeNode) 
    {
        treeNode.parent = this;
        treeNode.next = null;

        if (firstChild == null) 
        {
            // First child
            firstChild = treeNode;
            lastChild = treeNode;
            treeNode.prev = null;
        } 
        else 
        {
            // Second and other children.
            lastChild!.next = treeNode;
            treeNode.prev = lastChild;
            lastChild = treeNode;
        }
    }
}

abstract class InterfaceToDynamic 
{
    dynamic toDynamic(bool embeded);
}