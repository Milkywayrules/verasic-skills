/**
 * Verasic repo config hub — shared types and defaults.
 * Consumer repos copy templates/verasic.config.ts.example → verasic.config.ts
 * or use .verasicrc.json / .verasicrc.jsonc at repo root.
 */

export type SecurityReviewScanner = 'off' | 'semgrep' | 'opengrep' | 'auto';

export type SecurityReviewStrictness = 'strict' | 'assertive';

export type SecurityReviewPromote = 'both' | 'local' | 'tracked';

export type VerasicConfig = {
  artifacts: {
    /** Durable, commit-friendly artifact root (indexed by default). */
    trackedDir: string;
    /** Gitignored machine-local artifact root; pairs with trackedDir. */
    localDir: string;
    /** When false, scaffold may add localDir to .cursorignore. */
    indexLocal: boolean;
  };
  securityReview: {
    scanner: SecurityReviewScanner;
    strictness: SecurityReviewStrictness;
    report: {
      write: boolean;
      promote: SecurityReviewPromote;
    };
  };
};

export const DEFAULT_VERASIC_CONFIG: VerasicConfig = {
  artifacts: {
    trackedDir: 'verasic',
    localDir: '.verasic',
    indexLocal: false,
  },
  securityReview: {
    scanner: 'off',
    strictness: 'strict',
    report: {
      write: true,
      promote: 'both',
    },
  },
};

export default DEFAULT_VERASIC_CONFIG;
