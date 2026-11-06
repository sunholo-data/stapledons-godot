# Development targets use isolated local-package overlays. Activate production
# calib-smoke/calibrate only after the registry pins and S2 backend exist.
.PHONY: calib-dev-test calib-dev-smoke calib-dev-parity calib-dev calib-dev-interpreter
calib-dev-test:
	AILANG=$(AILANG) tools/calibration_dev.sh test
calib-dev-smoke:
	AILANG=$(AILANG) tools/calibration_dev.sh smoke
calib-dev-parity:
	AILANG=$(AILANG) tools/calibration_dev.sh parity
calib-dev:
	AILANG=$(AILANG) tools/calibration_dev.sh emit
calib-dev-interpreter:
	AILANG=$(AILANG) tools/calibration_dev.sh interpreter data/worlds/calibration-development-interpreter.json
