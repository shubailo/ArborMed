const { execFileSync } = require('child_process');
try {
  execFileSync('node', ['-e', 'console.log("hello")'], { stdio: 'inherit' });
} catch (e) {
  console.log(e);
}
