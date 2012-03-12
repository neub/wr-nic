#!   /usr/bin/env   python
#    coding: utf8

class PtsException(Exception):
    pass

class PtsCritical(PtsException):
    """critical error, abort the whole test suite"""
    pass

class PtsError(PtsException):
    """error, continue remaining tests in test suite"""
    pass

class PtsUser(PtsException):
    """error, user intervention required"""
    pass

class PtsWarning(PtsException):
    """warning, a cautionary message should be displayed"""
    pass

class PtsInvalid(PtsException):
    """reserved: invalid parameters"""

class PtsNoBatch(PtsInvalid):
    """reserved: a suite was created without batch of tests to run"""
    pass

class PtsBadTestNo(PtsInvalid):
    """reserved: a bad test number was given"""
    pass

if __name__ == '__main__':
    pass
