document.addEventListener('DOMContentLoaded', () => {
    const observerOptions = {
        root: null, // Use the viewport as the root
        rootMargin: '0px',
        threshold: 0.1 // Trigger when 10% of the element is visible
    };

    // --- Text Translation Effect ---
    const translateElements = [
        { section: '.one-app-section', h1: '.one-app-content h1', p: '.one-app-content p', factor: 5 },
        { section: '.routine-section', h1: '.routine-content h1', p: '.routine-content p', factor: 5 }
    ];

    translateElements.forEach(item => {
        const section = document.querySelector(item.section);
        const h1 = section?.querySelector(item.h1);
        const p = section?.querySelector(item.p);

        if (section && h1 && p) {
            window.addEventListener('scroll', () => {
                const rect = section.getBoundingClientRect();
                const windowHeight = window.innerHeight;

                // Calculate scroll progress within the section (0 to 1)
                // Consider the element visible from when its top enters the bottom of the viewport
                // until its bottom leaves the top of the viewport.
                const scrollAmount = windowHeight - rect.top;
                const totalScrollHeight = windowHeight + rect.height;
                let progress = scrollAmount / totalScrollHeight;
                progress = Math.max(0, Math.min(1, progress)); // Clamp between 0 and 1

                // Calculate translation based on progress (moves from -factor% to +factor%)
                const translateH1 = -item.factor + (progress * item.factor * 2);
                const translateP = item.factor - (progress * item.factor * 2);

                h1.style.transform = `translateX(${translateH1}%)`;
                p.style.transform = `translateX(${translateP}%)`;
            });
        }
    });

    // --- Highlight Features Text Color Change ---
    const highlightTextSection = document.querySelector('.highlight-features-section');
    const highlightTexts = document.querySelectorAll('.highlight-text h1');

    if (highlightTextSection && highlightTexts.length > 0) {
        const highlightObserver = new IntersectionObserver((entries) => {
            let mostVisibleEntry = null;
            let maxVisibility = 0;

            entries.forEach(entry => {
                if (entry.intersectionRatio > maxVisibility) {
                    maxVisibility = entry.intersectionRatio;
                    mostVisibleEntry = entry.target;
                }
                // Fallback if ratios are equal or very small, prioritize the one closer to center
                else if (entry.intersectionRatio === maxVisibility && mostVisibleEntry) {
                     const currentEntryCenter = entry.boundingClientRect.top + entry.boundingClientRect.height / 2;
                     const mostVisibleCenter = mostVisibleEntry.getBoundingClientRect().top + mostVisibleEntry.getBoundingClientRect().height / 2;
                     if (Math.abs(window.innerHeight / 2 - currentEntryCenter) < Math.abs(window.innerHeight / 2 - mostVisibleCenter)) {
                         mostVisibleEntry = entry.target;
                     }
                }
            });

            highlightTexts.forEach(text => {
                text.classList.remove('active');
            });

            if (mostVisibleEntry) {
                 // Check if the section itself is sufficiently visible
                 const sectionRect = highlightTextSection.getBoundingClientRect();
                 const sectionInView = sectionRect.top < window.innerHeight * 0.8 && sectionRect.bottom > window.innerHeight * 0.2;

                 if(sectionInView){
                    mostVisibleEntry.classList.add('active');
                 }
            } else {
                 // If no text is clearly most visible (e.g., scrolling fast), maybe highlight the middle one?
                 // Or default to the first/last based on scroll direction? For now, just remove active class.
            }

        }, {
            root: null,
            rootMargin: '-40% 0px -40% 0px', // Trigger when element is closer to the vertical center
            threshold: Array.from({ length: 11 }, (_, i) => i * 0.1) // Multiple thresholds for better ratio calculation
        });

        highlightTexts.forEach(text => {
            highlightObserver.observe(text);
        });
    }


    // --- Fully Featured Text Color Change ---
    const fullyFeaturedSection = document.querySelector('.fully-featured-section');
    const fullyFeaturedTexts = fullyFeaturedSection?.querySelectorAll('h1');

    if (fullyFeaturedSection && fullyFeaturedTexts?.length > 0) {
        window.addEventListener('scroll', () => {
            const rect = fullyFeaturedSection.getBoundingClientRect();
            const windowHeight = window.innerHeight;
            const sectionHeight = fullyFeaturedSection.offsetHeight;

            // Calculate when the center of the section aligns with the center of the viewport
            const sectionCenter = rect.top + sectionHeight / 2;
            const screenCenter = windowHeight / 2;

            // Calculate progress based on how close the section center is to the screen center
            // Progress is 0 when center is far, 1 when centers align
            const distance = Math.abs(screenCenter - sectionCenter);
            // Normalize distance based on half the screen height (or adjust sensitivity)
            let progress = 1 - Math.min(1, distance / (windowHeight * 0.4)); // Adjust 0.4 for sensitivity

             // Make the transition sharper around the center
             progress = Math.pow(progress, 3); // Cube the progress for a sharper curve

            // Interpolate color from gray-600 (#6b7280) to white (#ffffff)
            const startColor = { r: 107, g: 114, b: 128 }; // #6b7280
            const endColor = { r: 255, g: 255, b: 255 }; // #ffffff

            const r = Math.round(startColor.r + (endColor.r - startColor.r) * progress);
            const g = Math.round(startColor.g + (endColor.g - startColor.g) * progress);
            const b = Math.round(startColor.b + (endColor.b - startColor.b) * progress);

            fullyFeaturedTexts.forEach(text => {
                text.style.color = `rgb(${r}, ${g}, ${b})`;
            });
        });
    }

});
