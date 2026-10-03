import React, {useEffect, useRef} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import media from '@site/src/data/media.json';

// A looping, muted capture from the game. Sources come from
// src/data/media.json (written by `make site-media-publish`): content-addressed
// files in the public bucket gs://stapledons-voyage-assets/site/. The poster is
// the clip's first frame, committed under static/img/posters/.
//
// Clips play only while on screen, and not at all when the viewer asks for
// reduced motion (they can still press play).
// `sound` clips (e.g. a voice) never autoplay: they show controls, start muted=false, and wait
// for the viewer.
export default function Clip({name, className, label, controls = false, eager = false, sound = false}) {
  const ref = useRef(null);
  const clip = media[name];
  const poster = useBaseUrl(`/img/posters/${name}.jpg`);

  useEffect(() => {
    const v = ref.current;
    if (!v || sound) return undefined;
    const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduce) {
      v.controls = true;
      return undefined;
    }
    if (!('IntersectionObserver' in window)) {
      v.play().catch(() => {});
      return undefined;
    }
    const io = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) v.play().catch(() => {});
        else v.pause();
      },
      {threshold: 0.2},
    );
    io.observe(v);
    return () => io.disconnect();
  }, [sound]);

  if (!clip) return null;
  return (
    <video
      ref={ref}
      className={className}
      poster={poster}
      muted={!sound}
      loop={!sound}
      playsInline
      controls={controls || sound}
      preload={eager ? 'auto' : 'none'}
      aria-label={label}
      title={label}>
      <source src={clip.webm.url} type="video/webm" />
      <source src={clip.mp4.url} type="video/mp4" />
    </video>
  );
}

// A figure for docs pages: the clip plus a caption.
export function ClipFigure({name, caption, sound = false}) {
  return (
    <figure className="sv-figure">
      <Clip name={name} label={caption} controls sound={sound} />
      <figcaption>{caption}</figcaption>
    </figure>
  );
}
