### Fixed

`make free-nav-stop-test` (free navigation, I offers the destination and alpha Cen A
is inspectable) was red on main since PR #379 put the course monitor on the eye's
forward look: `free-nav-stop: 48 passed, 2 failures`. The test now looks from the
golden's clear captain eye (G-M4-S3, `(11, 82, -4.8)`) and checks before each I
offer that no ship surface blocks that eye's centre ray, so a future furniture move
names the eye. The product is unchanged (row 7ak).
