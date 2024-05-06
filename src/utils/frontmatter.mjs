import lazyLoadPlugin from 'rehype-plugin-image-native-lazy-loading';

export function responsiveTablesRehypePlugin() {
  return function (tree) {
    if (!tree.children) return;

    for (let i = 0; i < tree.children.length; i++) {
      const child = tree.children[i];
      if (child.type === 'element' && child.tagName === 'table') {
        const wrapper = {
          type: 'element',
          tagName: 'div',
          properties: {
            style: 'overflow:auto',
          },
          children: [child],
        };
        tree.children[i] = wrapper;

        i++;
      }
    }
  };
}

export const lazyImagesRehypePlugin = lazyLoadPlugin;
