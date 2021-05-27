from __future__ import print_function

import os
import pwd
import grp
import shutil

from irods.configuration import IrodsConfig
from irods import paths

def main():

    src_core_py_tpl = os.path.join(paths.config_directory(), 'core.py.template')
    dst_core_py = os.path.join(paths.config_directory(), 'core.py')
    shutil.copy(src_core_py_tpl , dst_core_py)
    if os.getuid() == 0:
        try:
            os.chown( dst_core_py,
                      pwd.getpwnam('irods').pw_uid,
                      grp.getgrnam('irods').gr_gid)
        except KeyError: pass

    irods_config = IrodsConfig()
    irods_config.server_config['plugin_configuration']['rule_engines'] = [
            {
                'instance_name': 'irods_rule_engine_plugin-python-instance',
                'plugin_name': 'irods_rule_engine_plugin-python',
                'plugin_specific_configuration': {}
            }
        ]
    irods_config.commit(irods_config.server_config, irods_config.server_config_path, make_backup=True)

if __name__ == '__main__':
    main()
