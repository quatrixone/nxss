# Contributing to NXSS

Thank you for your interest in contributing to NXSS! We welcome contributions from the community and appreciate your help in making this project better.

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Check existing issues** - Make sure the issue hasn't been reported already
2. **Use the issue template** - Fill out all relevant sections
3. **Provide details** - Include steps to reproduce, expected behavior, and actual behavior
4. **Include system info** - OS, Node.js version, Flutter version, etc.

### Suggesting Features

We love feature suggestions! Please:

1. **Check the roadmap** - See if it's already planned
2. **Describe the use case** - Explain why this feature would be useful
3. **Consider implementation** - Think about how it might work
4. **Be specific** - Detailed descriptions help us understand your needs

### Code Contributions

#### Getting Started

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/your-username/nxss.git
   cd nxss
   ```

3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Install dependencies**:
   ```bash
   npm install
   cd clients/flutter && flutter pub get
   ```

#### Development Guidelines

##### Code Style

- **JavaScript/Node.js**: Follow standard JavaScript conventions
- **Dart/Flutter**: Follow Dart style guide and Flutter conventions
- **Comments**: Write clear, helpful comments
- **Naming**: Use descriptive variable and function names

##### Commit Messages

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add folder pairing with server folder selection"
git commit -m "Fix sync error when folder is empty"
git commit -m "Update README with Docker setup instructions"

# Avoid
git commit -m "fix"
git commit -m "update"
git commit -m "stuff"
```

##### Testing

- **Test your changes** - Make sure everything works as expected
- **Test on multiple platforms** - If possible, test on different OS
- **Test edge cases** - Consider error conditions and edge cases
- **Update tests** - Add or update tests for new functionality

#### Pull Request Process

1. **Update documentation** - Update README, comments, or other docs as needed
2. **Test thoroughly** - Make sure your changes work correctly
3. **Create pull request** - Use the PR template
4. **Respond to feedback** - Address any review comments
5. **Keep PR focused** - One feature or fix per PR

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on [platform]
- [ ] Added tests for new functionality
- [ ] All existing tests pass

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly marked)
```

## 🏗️ Development Setup

### Prerequisites

- **Node.js** 18+ and npm
- **Flutter SDK** 3.0+ with desktop support
- **Git** for version control
- **Docker** (optional, for containerized development)

### Local Development

1. **Start the server**:
   ```bash
   cd server
   npm run dev
   ```

2. **Run the Flutter app**:
   ```bash
   cd clients/flutter
   flutter run -d linux  # or your preferred platform
   ```

3. **Make your changes** and test them

### Docker Development

```bash
# Start with Docker
cd server
docker compose up -d

# View logs
docker compose logs -f
```

## 📁 Project Structure

```
nxss/
├── server/                 # Backend server (Node.js/Express)
├── clients/
│   ├── cli/               # Command-line client
│   └── flutter/           # Mobile & desktop apps
├── builds/                # Built applications
├── scripts/               # Build and setup scripts
└── docs/                  # Documentation
```

## 🎯 Areas for Contribution

### High Priority
- **Bug fixes** - Fix reported issues
- **Documentation** - Improve README, code comments, guides
- **Testing** - Add unit tests, integration tests
- **Performance** - Optimize sync speed, memory usage

### Medium Priority
- **UI/UX improvements** - Better user interface
- **Error handling** - More robust error handling
- **Logging** - Better logging and debugging
- **Configuration** - More configuration options

### Low Priority
- **New features** - Additional functionality
- **Platform support** - Support for more platforms
- **Integrations** - Third-party service integrations

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment**:
   - OS and version
   - Node.js version
   - Flutter version (if applicable)
   - Browser (if applicable)

2. **Steps to reproduce**:
   - Clear, numbered steps
   - Expected behavior
   - Actual behavior

3. **Additional context**:
   - Screenshots or videos
   - Error messages
   - Log files
   - Related issues

## 💡 Feature Requests

When suggesting features:

1. **Use case**: Why is this feature needed?
2. **Proposed solution**: How should it work?
3. **Alternatives**: What other approaches were considered?
4. **Additional context**: Any other relevant information

## 📞 Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Code Review**: Ask for help with code reviews

## 🏆 Recognition

Contributors will be recognized in:
- **README.md** - Listed as contributors
- **Release notes** - Mentioned in relevant releases
- **GitHub** - Shown in contributors list

## 📋 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive experience for everyone, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience, education
- Nationality, personal appearance
- Race, religion, sexual orientation

### Our Standards

**Positive behavior**:
- Using welcoming and inclusive language
- Being respectful of different viewpoints
- Accepting constructive criticism
- Focusing on what's best for the community

**Unacceptable behavior**:
- Harassment, trolling, or inappropriate comments
- Personal attacks or political discussions
- Public or private harassment
- Other unprofessional conduct

### Enforcement

Project maintainers will:
- Remove inappropriate content
- Warn or ban repeat offenders
- Take other appropriate action

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to NXSS! 🎉
