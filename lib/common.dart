import 'package:path/path.dart' as p;
import 'package:path/path.dart' as p;

/// Converts an instance to the requested nullable type
/// - Returns an object of the desired type, or null if type conversion is not possible
T? toNullableType<T>(Object instance)
{
    if (instance is T)
    {
        return instance as T;
    }
    else
    {
        return null;
    }
}

/// Set of unicode whitespace characters
const whiteCharacters = <int>
{
    0x09,
    0x0a,
    0x0b,
    0x0c,
    0x0d,
    0x20,
    0x85,
    0xa0,
    0x1680,
    0x180e,
    0x2000,
    0x2001,
    0x2002,
    0x2003,
    0x2004,
    0x2005,
    0x2006,
    0x2007,
    0x2008,
    0x2009,
    0x200A,
    0x200B,
    0x202F,
    0x205F,
    0x3000,
    0xFEFF
};

/// Returns true if the string is contains only whitespace characters or the string is null
bool isBlankOrNull(String? value)
{
    if (value == null)
    {
        return true;
    }
    else
    {
        for (var i = 0; i < value.length; i++)
        {
            if (!whiteCharacters.contains(value.codeUnitAt(i)))
            {
                return false;
            }
        }

        return true;
    }
}

/// Regular expression for match a double number in the text
var numberFromText = RegExp(r'(\-?\d+(\.\d+)?([eE]\-?\d+)?)|(\-?\.?\d+)');

/// Converts dynamic to double
/// - double returns double
/// - int returns int converted to double
/// - string parse to a double or use [numberFromText] for a match number.
/// - returns defNumber if it fails.
double dynamicToDouble(dynamic value,[double defValue=0.0])
{
    if (value is double)
    {
        return value;
    }
    else if (value is int)
    {
        return value.toDouble();
    }
    else
    {
        var valStr = value.toString().trim().replaceAll(',', '.');
        var res = double.tryParse(valStr);

        if (res == null)
        {
            var match = numberFromText.firstMatch(valStr);
            if (match != null)
            {
                valStr = match.input.substring(match.start,match.end);

                if (valStr.startsWith('.'))
                {
                  valStr = '0'+valStr;
                }

                if (valStr.startsWith('-.'))
                {
                  valStr = '-0'+valStr.substring(1);
                }

                res = double.tryParse(valStr);
            }
        }

        return res ?? defValue;
    }
}

double saturate(double value, double min, double max)
{
    if (value<min)
    {
        return min;
    }
    else if (value > max)
    {
        return max;
    }
    else
    {
        return value;
    }
}

int saturateInt(int value, int min, int max)
{
    if (value<min)
    {
        return min;
    }
    else if (value > max)
    {
        return max;
    }
    else
    {
        return value;
    }
}


class FileUtils
{
    /// Path combination
    ///
    /// Returns a path that is a combination of an absolutely specified file ([filePath]) path
    /// and a relative path ([relativePath])
    static String relativePathFromFile(String filePath,String relativePath)
    {
        final path = p.join(p.dirname(filePath),relativePath);
        final pathComp = p.split(path);
        final filteredPath = <String>[];

        for(var comp in pathComp)
        {
            if (comp == '..' && filteredPath.isNotEmpty)
            {
                filteredPath.removeLast();
            }
            else if (comp != '.')
            {
                filteredPath.add(comp);
            }
        }

        return p.joinAll(filteredPath);

    }
}


extension StringFunctions on String
{
    List<int> copyToCodeUnits()
    {
        return List<int>.from(codeUnits);
    }

}