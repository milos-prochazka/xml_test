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

extension StringFunctions on String
{
    List<int> copyToCodeUnits()
    {
        return List<int>.from(codeUnits);
    }

}