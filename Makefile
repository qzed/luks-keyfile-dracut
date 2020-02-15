.PHONY: install uninstall

DRACUT_MODULES_D=/usr/lib/dracut/modules.d
DRACUT_CONF_D=/etc/dracut.conf.d

MODULE_CONF_D=dracut.conf.d
MODULE_CONF=luks-keyfile.conf
MODULE_DIR=96luks-keyfile

help:
	@echo make help to show this help
	@echo make install to install
	@echo make uninstall to remove

install:
	cp ${MODULE_CONF_D}/${MODULE_CONF} ${DRACUT_CONF_D}/
	cp -r ${MODULE_DIR} ${DRACUT_MODULES_D}/
	dracut -fv

uninstall:
	rm ${DRACUT_CONF_D}/${MODULE_CONF}
	rm -r ${DRACUT_MODULES_D}/${MODULE_DIR}
	dracut -fv
