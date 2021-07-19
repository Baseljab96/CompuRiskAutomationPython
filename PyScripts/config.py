import datetime as dt
from datetime import datetime
import pathlib
#import pandas as pd

__all__ = ['Paths']

class Paths:
    _paths = {
        'workdir': 'C:\\Users\\baselj\Desktop\FDB_Automation\Archive\{YYYYMMDD}',
        'templatedir': 'C:\\Users\\baselj\Desktop\FDB_Automation\Template',
        'datadir': 'C:\\Users\\baselj\Desktop\FDB_Automation\Data',
        'logsdir': '{workdir}\\Output\\Logs',
        'reportsdir': '{workdir}\\Output\\Logs',
        'tempdir': '{workdir}\\Output\\Temp'
        
    }
    _placeholders = {
        'YYYYMMDD': '%Y%m%d',
    }
    def __init__(self, date=None):
        self.date = date if date is not None else dt.datetime.today()
    
    def __getattr__(self, item):
        if item in self._paths:
            path = self._paths[item]
            return pathlib.Path(self.date.strftime(path).format(**{
                ph: self.date.strftime(fmt)
                for ph, fmt in self._placeholders.items()
            }))
        raise AttributeError(f"'{self.__class__.__name__}' object has no attribute '{item}'")

