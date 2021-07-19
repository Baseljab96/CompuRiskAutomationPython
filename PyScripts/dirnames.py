import datetime as dt
from datetime import datetime
#import pandas as pd

__all__ = ['Paths']

class Paths:
    _paths = {
        'workdir': 'C:\\Users\baselj\Desktop\FDB_Automation\Archive\{YYYYMMDD}',
        'tempdir': 'C:\\Users\baselj\Desktop\FDB_Automation\Template',
        'datadir': 'C:\\Users\baselj\Desktop\FDB_Automation\Data'
    }
    _placeholders = {
        'YYYYMMDD': '%Y%m%d',
    }
    def __init__(self, date=None):
        self.date = date if date is not None else dt.datetime.today()
    
    def __getattr__(self, item):
        if item in self._paths:
            path = self._paths[item]
            return self.date.strftime(path).format(**{
                ph: self.date.strftime(fmt)
                for ph, fmt in self._placeholders.items()
            })
        raise AttributeError(f"'{self.__class__.__name__}' object has no attribute '{item}'")

date = dt.datetime.strptime('20200101','%Y%m%d')
paths = Paths(date)
print(paths.workdir)
