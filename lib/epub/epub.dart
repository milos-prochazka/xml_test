import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:html/dom.dart';
import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';

import 'package:xml/xml.dart';
import 'package:xml_test/epub/CssDocument.dart';
import 'package:xml_test/xml/xnode.dart' as xnode;
import 'package:xml_test/common.dart';

import 'CssDocument.dart';
import 'DefaultCss.dart';

/// Loading and working with epub files
class Epub
{
    /// Dictionary of files in the archive
    var files = <String, ArchiveFile>{};

    /// Manifest dictionary, index Id (from .opf file)
    var manifest = <String, ManifestItem>{};

    /// Manifest dictionary, index href (from .opf file)
    var manifestHref = <String, ManifestItem>{};

    // Spine List (from .opf file)
    var spineList = <ManifestItem>[];

    // Document List (HTML/XHTML from .opf file)
    var documents = <xnode.XNode>[];

    /// Big docucument (merged documents)
    var bigDocument = xnode.XNode.body();

    /// Navigation points (short names)
    var shortNavigation = <String, NavigationPoint>{};

    /// Navigation points (long names)
    var longNavigation = <String, NavigationPoint>{};

    /// Constructor (form [Archive])
    Epub(Archive archive)
    {
        _loadArchive(archive);
    }

    /// Load the archive contents
    void _loadArchive(Archive archive)
    {
        for (final file in archive)
        {
            print(file.name);
            if (file.name.contains('page_styles.css'))
            {
                var brk = 1;
            }
            final filename = file.name;
            files[filename] = file;
        }

        for (var file in files.values)
        {
            if (file.isFile)
            {
                if (file.name.endsWith('.opf'))
                {
                    var strText = utf8.decode(file.content as List<int>, allowMalformed: true);
                    _loadOpf(strText);
                }
            }
        }

//#debug
// Test code
        for (var cs in manifest.values)
        {
            cs.$$$(this);
        }
//#end
        _loadDocumentFiles();
    }

    /// Loads opf file
    /// - Creates manifest
    /// - Creates spneList (list of document htmls)
    void _loadOpf(String xmlText)
    {
        var doc = XmlDocument.parse(xmlText);
        var opf = xnode.XNode.fromXmlDocument(doc);

        // Load manifest
        var manifestNodes = opf.getChildren(['package', 'manifest'], childNames: {'item'});

        for (var item in manifestNodes)
        {
            var manfestItem = ManifestItem(item, files);
            if (manfestItem.valid)
            {
                manifest[manfestItem.id] = manfestItem;
                manifestHref[manfestItem.href] = manfestItem;
            }

            print(manfestItem.toString());
        }

        // Load spine
        var spineNodes = opf.getChildren(['package', 'spine'], childNames: {'itemref'});

        for (var itemref in spineNodes)
        {
            var idref = itemref.attributes['idref'];

            if (idref != null && manifest.containsKey(idref))
            {
                spineList.add(manifest[idref]!);
            }
        }
    }

    /// Loads files in the spineList (document content)
    /// - Loads files in the smineList and adds them to the document list.
    void _loadDocumentFiles()
    {
        for (var item in spineList)
        {
            bigDocument.children.add(xnode.XNode.comment('\r\n --- ${item.id} (${item.file.name}) --\r\n'));
            var node = item.xmlNode;
            var body = node.getChildren(['html', 'body']);
            var first = true;

            for (var node in body)
            {
                _navigation(item.file.name, node, first);
                first = false;
                bigDocument.children.add(node);
            }
            documents.add(node);
        }
    }

    void _navigation(String docId, xnode.XNode node, bool firstNode)
    {
        node.linkedData['docId'] = docId;

        if (firstNode)
        {
            _addNavigationPoint(node, NavigationPoint('', docId, node));
        }

        var id = node.attributes['id'];
        if (id != null)
        {
            _addNavigationPoint(node, NavigationPoint(id, docId, node));
        }

        for (var child in node.children)
        {
            _navigation(docId, child, false);
        }
    }

    void _addNavigationPoint(xnode.XNode node, NavigationPoint navPoint)
    {
        node.linkedData['longNavigation'] = navPoint;
        if (navPoint.id != '')
        {
            node.linkedData['shortNavigation'] = navPoint;
            shortNavigation['#' + navPoint.id] = navPoint;
            longNavigation[navPoint.file + '#' + navPoint.id] = navPoint;
        }
        else
        {
            longNavigation[navPoint.file] = navPoint;
        }
    }
}

class ManifestItem
{
    late String href;
    late String id;
    late String media_type;
    late ArchiveFile file;

    xnode.XNode? _xmlNode;
    List<int>? _bytes;
    CssDocument? _cssDocument;
    String? _text;
    List<CssDocument>? _containedCss;

    bool valid = false;

    static final mimeRegex = RegExp(r'(?<=[\/\+])[\w\-\.]+');

    ManifestItem(xnode.XNode item, Map<String, ArchiveFile> files)
    {
        final _href = item.attributes['href'];
        final _id = item.attributes['id'];
        final _media_type = item.attributes['media-type'] ?? '';

        if (_href!.contains("page_styles"))
        {
            var brk = 1;
        }

        if (_href != null && _id != null)
        {
            if (files.containsKey(_href))
            {
                href = _href;
                id = _id;
                media_type = _media_type;
                file = files[_href]!;
                valid = true;

                var types = mimeTypes;
            }
        }
    }

    Set<String> get mimeTypes
    {
        var result = <String>{};

        var matches = mimeRegex.allMatches(media_type);

        for (var match in matches)
        {
            var str = match.input.substring(match.start, match.end);
            if (!result.contains(str))
            {
                result.add(str);
            }
        }
        return result;
    }

    List<int> get bytes
    {
        _bytes ??= file.content as List<int>;
        return _bytes as List<int>;
    }

    String get text
    {
        return utf8.decode(bytes, allowMalformed: true);
    }

    xnode.XNode get xmlNode
    {
        var mime = mimeTypes;

        if (_xmlNode == null)
        {
            if (mime.containsAll(['html', 'xhtml']))
            {
                var strText = utf8.decode(bytes);
                _xmlNode = xnode.XNode.fromHtmlDocument(html.parse(strText));
            }
            else if (mime.contains('xml'))
            {
                var strText = utf8.decode(bytes);
                _xmlNode = xnode.XNode.fromXmlDocument(XmlDocument.parse(strText));
            }
            else
            {
                _xmlNode = xnode.XNode();
            }
        }

        return _xmlNode as xnode.XNode;
    }

    CssDocument? get CSS
    {
        var mime = mimeTypes;

        if (_cssDocument == null)
        {
            if (mime.contains('css'))
            {
                _cssDocument = CssDocument(utf8.decode(bytes));
            }
        }

        return _cssDocument;
    }

    List<CssDocument> getCssDocuments(Epub epub)
    {

        if (_containedCss == null)
        {
            _containedCss  = <CssDocument>[];

            _addCSS(xmlNode, _containedCss!, epub);
        }

        return _containedCss!;
    }

    Map<String, CssDeclarationResult> getNodeStyle(Epub epub,xnode.TreeNode node)
    {
        var resultHolder = <String, CssDeclarationResult>{};

        for(final css in getCssDocuments(epub))
        {
            css.getNodeStyle(node,resultHolder);
        }

        node.style = 'color: #cdea';

        if (node.style != '')
        {
            var style = '${CssDocument.INLINE_STYLE_SELECTOR} {${node.style}}';

            var css = CssDocument(style);

            css.getNodeStyle(node);
        }

        return resultHolder;
    }


    void _addCSS(xnode.XNode node, List<CssDocument> cssList, Epub epub)
    {
        if (node.name == 'link' &&
                (node.attributeContains('link', 'stylesheet') || node.attributeContains('type', 'css')))
        {
            var cssPath = FileUtils.relativePathFromFile(href, node.attributes['href']!);
            var cssManifest = epub.manifestHref[cssPath];

            if (cssManifest != null)
            {
                var doc = cssManifest.CSS;
                if (doc != null)
                {
                    cssList.add(doc);
                }
            }
        }
        else
        {
            for (final child in node.children)
            {
                _addCSS(child, cssList, epub);
            }
        }
    }

    void $$$(Epub epub)
    {
        var mime = mimeTypes;

        if (mime.contains('css'))
        {
            // var strText = utf8.decode(bytes).replaceAll('1em', '3.3mm');
            //var strText = 'h1,p.prvni.druha { color: rgb(12em,30,233,555,333); } div { animation: mymove 5s infinite; text-shadow: 2px 2px 5px red; } ';
            var strText = '''
@keyframes mymove {
  from {top: 0px;}
  to {top: 200px;}
}
@page {
    margin-bottom: 5pt;
    margin-top: 5pt
    }
@charset "UTF-8";
@font-face {
    font-family: "DejaVuSerifCondensed";
    font-weight: normal;
    font-style: normal;
    src: url(OPS/fonts/DejaVuSerifCondensed.ttf)
    }
@media only screen and (max-width: 600px) {
  body {
    background-color: lightblue;
  }
}
''';
            strText = this.text;
            var stylesheet = css.parse(strText);
            var qq = stylesheet.topLevels[0];
            var debug = stylesheet.toDebugString();
            File('out/list${file.name}')
                ..createSync(recursive: true)
                ..writeAsBytesSync(utf8.encode(debug));

            var jj = qq.span;

            print(jj.toString());

            print('--------------------------------------------');
            var cs = CssDocument(strText);
            //print (cs.toString());
            File('out/decoded.css')
                ..createSync(recursive: true)
                ..writeAsBytesSync(utf8.encode(cs.toString()));

            var brk = 1;
        }
        else if (mime.contains('html') || mime.contains('xhtml'))
        {
            var styles = getCssDocuments(epub);
            var tnode = xnode.TreeNode.fromXNode(xmlNode);
            $$$testTNode(epub,styles, tnode);
        }
    }

    void $$$testTNode(Epub epub,List<CssDocument> css, xnode.TreeNode node)
    {
        for (final doc in css)
        {
            var decl = doc.findDeclaration(node, 'color');
            if (decl.declaration != null)
            {
                final brk = 1;
            }

            var style = getNodeStyle(epub, node); //doc.getNodeStyle(node);

            if (style.isNotEmpty)
            {
                var list = style.entries.toList();
                list.sort((a,b) => a.key.compareTo(b.key));
                final brk = 1;
            }
        }

        var child = node.firstChild;

        while (child != null)
        {
            $$$testTNode(epub,css, child);
            child = child.next;
        }
    }

    @override
    String toString()
    {
        return (valid) ? 'id:$id media-type:$media_type href:$href' : 'invalid';
    }
}

class NavigationPoint
{
    late String id;
    late String file;
    late xnode.XNode node;
    bool reference = false;
    var linkedData = <String, dynamic>{};

    NavigationPoint(this.id, this.file, this.node);

    @override
    String toString()
    {
        return 'id:$id file:$file reference:$reference';
    }
}