#import "@preview/acrostiche:0.7.0": acr

= Verification

== Quality Assurance

Software engineering offers some common practices for increasing high quality code throughout a project. One of these practices is the usage of formatters and linters. As the name implies, the formatter automatically aligns the formatting for all files with the style guide @rustfmt. Linters perform static code analysis to catch common code mistakes, increase performance or enforce rules @clippy. Rust's default formatter `rustfmt` and linter `clippy` were both used in `beacon` and `sstv`. `clippy` was even used in `sstv` to guarentee the program could not crash at run time via a strict rule set.

Another software engineering practice is unit testing where the run time environment is simulated to verify certain behaviors in a deterministic manner. Extensive unit testing was used in `sstv` to ensure compatibility with the Dayton paper and other #acr("SSTV") programs. Testing `beacon` proved comparatively more difficult because unit tests by design have to be run on the device developing the code and not the target device. However, the traits described in section @sec-beacon-architecture make this possible. Since the entry points only depend on the `Camera`, `AudioChannel` and `CommandLink` traits, the real devices can be replaced with lightweight fakes running on the development machine. This lets the behaviour of `idle()` and `transmit_sstv()` be verified deterministically without the target hardware present.

However, these practices only generate an impact on the code base if they are consistently enforced. For that reason, both repositories use `pre-commit`. This tool installs a hook into the respective `git` repositories running among others the formatter, the linter and the unit tests before each commit. If any of those checks fail, the commit is aborted. If the developer does not have `pre-commit` installed locally, a GitHub Action catches the issues and sends out an automatic email communicating the failure. While these measures raise the bar for contributing to the repository, they prevent low quality and faulty code from entering the `git` history in the first place, ensuring that reverting to any commit yields safe state.

== Requirements

- show hardware setup
- for each requirement, have a test

== Modularity

- show an example on how another camera could be added
- show an example of the code for a raspberry pi with a camera and a speaker

