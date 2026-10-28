// Tailwind, then the site template's confine plugin: a sheet that opens with
// `/*! @confine .marker */` applies only in documents that contain `.marker`, which keeps a route
// group's sheet off the routes a reader navigates to from it (site-template/postcss/confine.cjs
// says why). A sheet without the directive passes through unchanged.
export default {
  plugins: {
    "@tailwindcss/postcss": {},
    "@agenticdevelopertoolkit/site-template/postcss-confine": {},
  },
};
